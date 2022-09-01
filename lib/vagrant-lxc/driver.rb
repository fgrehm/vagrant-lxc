require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"
require "vagrant-lxc/driver/cli"
require "vagrant-lxc/sudo_wrapper"

require "etc"

require "tempfile"

module Vagrant
  module LXC
    class Driver
      # This is raised if the container can't be found when initializing it with
      # a name.
      class ContainerNotFound < StandardError; end

      # Default root folder where container configs are stored
      attr_reader :container_name,
                  :customizations

      def initialize(container_name, sudo_wrapper = nil, cli = nil, privileged: true)
        @container_name = container_name
        @sudo_wrapper   = sudo_wrapper || SudoWrapper.new(privileged: privileged)
        @cli            = cli || CLI.new(@sudo_wrapper, container_name)
        @logger         = Log4r::Logger.new("vagrant::provider::lxc::driver")
        @customizations = []
      end

      def validate!
        raise ContainerNotFound if @container_name && ! @cli.list.include?(@container_name)
      end

      # Root folder where container configs are stored
      def containers_path
        @containers_path ||= @cli.config('lxc.lxcpath')
      end

      def all_containers
        @cli.list
      end

      def base_path
        Pathname.new("#{containers_path}/#{@container_name}")
      end

      def config_path
        base_path.join('config').to_s
      end

      def rootfs_path
        pathtype, path = config_string.match(/^lxc\.rootfs\.path\s+=\s+dir:(.+)$/)[1..2]
        case pathtype
        when 'overlayfs:'
          # Split on colon (:), ignoring any colon escaped by an escape character ( \ )
          # Pays attention to when the escape character is itself escaped.
          _, overlay_path = config_entry.split(/(?<!\\)(?:\\\\)*:/)
          if overlay_path
            Pathname.new(overlay_path)
          else
            # Malformed: fall back to prior behaviour
            Pathname.new(path)
          end
        else
          Pathname.new(path)
        end
      end

      def mac_address
        return @mac_address if @mac_address

        if config_string =~ /^lxc\.network\.hwaddr\s*+=\s*+(.+)$/
          @mac_address = $1
        end
      end

      def config_string
        @sudo_wrapper.run('cat', config_path)
      end

      def create(name, backingstore, backingstore_options, template_path, config_file, template_options = {})
        @cli.name = @container_name = name

        @logger.debug "Creating container..."

        @cli.create template_path, backingstore, backingstore_options, config_file, template_options
      end

      def share_folders(folders)
        folders.each do |f|
          share_folder(f[:hostpath], f[:guestpath], f.fetch(:mount_options, nil))
        end
      end

      def share_folder(host_path, guest_path, mount_options = nil)
        guest_path    = guest_path.gsub(/^\//, '').gsub(' ', '\\\040')
        mount_options = Array(mount_options || ['bind', 'create=dir'])
        host_path     = host_path.to_s.gsub(' ', '\\\040')
        @customizations << ['mount.entry', "#{host_path} #{guest_path} none #{mount_options.join(',')} 0 0"]
      end

      def start(customizations)
        @logger.info('Starting container...')

        if ENV['LXC_START_LOG_FILE']
          extra = ['-o', ENV['LXC_START_LOG_FILE'], '-l', 'DEBUG']
        end

        prune_customizations
        write_customizations(customizations + @customizations)

        @cli.start(extra)
      end

      def forced_halt
        @logger.info('Shutting down container...')
        @cli.transition_to(:stopped) { |c| c.stop }
      end

      def destroy
        @cli.destroy
      end

      def attach(*command)
        @cli.attach(*command)
      end

      def info(*command)
        @cli.info(*command)
      end

      def configure_private_network(bridge_name, bridge_ip, container_name, address_type, ip)
        @logger.info "Configuring network interface for #{container_name} using #{ip} and bridge #{bridge_name}"
        if ip
          ip += '/24'
        end

        if ! bridge_exists?(bridge_name)
          if not bridge_ip
            raise "Bridge is missing and no IP was specified!"
          end

          @logger.info "Creating the bridge #{bridge_name}"
          cmd = [
            'brctl',
            'addbr',
            bridge_name
          ]
          @sudo_wrapper.run(*cmd)
        end

        if ! bridge_has_an_ip?(bridge_name)
          if not bridge_ip
            raise "Bridge has no IP and none was specified!"
          end
          @logger.info "Adding #{bridge_ip} to the bridge #{bridge_name}"
          cmd = [
            'ip',
            'addr',
            'add',
            "#{bridge_ip}/24",
            'dev',
            bridge_name
          ]
          @sudo_wrapper.run(*cmd)
          @sudo_wrapper.run('ip', 'link', 'set', bridge_name, 'up')
        end

        cmd = [
          Vagrant::LXC.source_root.join('scripts/pipework').to_s,
          bridge_name,
          container_name,
          ip ||= "dhcp"
        ]
        @sudo_wrapper.run(*cmd)
      end

      def bridge_has_an_ip?(bridge_name)
        @logger.info "Checking whether the bridge #{bridge_name} has an IP"
        `ip -4 addr show scope global #{bridge_name}` =~ /^\s+inet ([0-9.]+)\/[0-9]+\s+/
      end

      def bridge_exists?(bridge_name)
        @logger.info "Checking whether bridge #{bridge_name} exists"
        brctl_output = `ip link | egrep -q " #{bridge_name}:"`
        $?.to_i == 0
      end

      def bridge_is_in_use?(bridge_name)
        # REFACTOR: This method is **VERY** hacky
        @logger.info "Checking if bridge #{bridge_name} is in use"
        brctl_output = `brctl show #{bridge_name} 2>/dev/null | tail -n +2 | grep -q veth`
        $?.to_i == 0
      end

      def remove_bridge(bridge_name)
        if ['lxcbr0', 'virbr0'].include? bridge_name
           @logger.info "Skipping removal of system bridge #{bridge_name}"
           return
        end

        return unless bridge_exists?(bridge_name)

        @logger.info "Removing bridge #{bridge_name}"
        @sudo_wrapper.run('ip', 'link', 'set', bridge_name, 'down')
        @sudo_wrapper.run('brctl', 'delbr', bridge_name)
      end

      def version
        @version ||= @cli.version.split('~', 2).first()
      end

      def supports_new_config_format
        Gem::Version.new(version) >= Gem::Version.new('2.1.0')
      end

      # TODO: This needs to be reviewed and specs needs to be written
      def compress_rootfs
        # TODO: Pass in tmpdir so we can clean up from outside
        target_path    = "#{Dir.mktmpdir}/rootfs.tar.gz"

        @logger.info "Compressing '#{rootfs_path}' rootfs to #{target_path}"
        @sudo_wrapper.run('tar', '--numeric-owner', '-cvzf', target_path, '-C',
          rootfs_path.parent.to_s, "./#{rootfs_path.basename.to_s}")

        @logger.info "Changing rootfs tarball owner"
        user_details = Etc.getpwnam(Etc.getlogin)
        @sudo_wrapper.run('chown', "#{user_details.uid}:#{user_details.gid}", target_path)

        target_path
      end

      def state
        if @container_name
          @cli.state
        end
      end

      def prune_customizations
        # Use sed to just strip out the block of code which was inserted by Vagrant
        @logger.debug 'Prunning vagrant-lxc customizations'
        contents = config_string
        contents.gsub! /^# VAGRANT-BEGIN(.|\s)*# VAGRANT-END\n/, ''
        write_config(contents)
      end

      def update_config_keys(path = nil)
        path = path || config_path
        @cli.update_config(path)
      rescue Errors::ExecuteError
        # not on LXC 2.1+. Doesn't matter, ignore.
      end

      protected

      def write_customizations(customizations)
        customizations = customizations.map do |key, value|
          "lxc.#{key}=#{value}"
        end
        customizations.unshift '# VAGRANT-BEGIN'
        customizations      << "# VAGRANT-END\n"

        contents = config_string
        contents << customizations.join("\n")

        write_config(contents)
      end

      def write_config(contents)
        confpath = base_path.join('config').to_s
        begin
          File.open(confpath, File::WRONLY|File::TRUNC) do |file|
            file.write contents
          end
        rescue
          # We don't have permissions to write in the conf file. That's probably because it's a
          # privileged container. Work around that through sudo_wrapper.
          Tempfile.new('lxc-config').tap do |file|
            file.chmod 0644
            file.write contents
            file.close
            @sudo_wrapper.run 'cp', '-f', file.path, confpath
            @sudo_wrapper.run 'chown', 'root:root', confpath
          end
        end
      end
    end
  end
end
