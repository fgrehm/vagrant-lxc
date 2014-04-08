require 'tempfile'

module Vagrant
  module LXC
    module Command
      class Sudoers < Vagrant.plugin("2", :command)

        def initialize(argv, env)
          super
          @env = env
        end

        def execute
          options = { user: ENV['USER'] }

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc sudoers"
            opts.separator ""
            opts.on('-u', '--user', "The user for which to create the policy (defaults to '#{options[:user]}')") do |u|
              options[:user] = u
            end
          end

          argv = parse_options(opts)
          return unless argv

          wrapper_path = Vagrant::LXC.sudo_wrapper_path
          wrapper = create_wrapper!
          sudoers = create_sudoers!(options[:user], wrapper_path)

          su_copy([
            {source: wrapper, target: wrapper_path, mode: "0555"},
            {source: sudoers, target: sudoers_path, mode: "0440"}
          ])
        end

        def sudoers_path
          "/etc/sudoers.d/vagrant-lxc-#{Vagrant::LXC::VERSION.gsub( /\./, '-')}"
        end

        private
        # REFACTOR: Make use ERB rendering after https://github.com/mitchellh/vagrant/issues/3231
        #           lands into core
        def create_wrapper!
          wrapper = Tempfile.new('lxc-wrapper').tap do |file|
            file.puts "#!/usr/bin/env ruby"
            file.puts "# Automatically created by vagrant-lxc"
            file.puts <<-EOF
class Whitelist
  class << self
    def add(command, *args)
      list[command] << args
    end

    def list
      @list ||= Hash.new do |key, hsh|
        key[hsh] = []
      end
    end

    def allowed(command)
      list[command] || []
    end

    def run!(argv)
      begin
        command, args = `which \#{argv.shift}`.chomp, argv || []
        check!(command, args)
        puts `\#{command} \#{args.join(" ")}`
        exit $?.to_i
      rescue => e
        STDERR.puts e.message
        exit 1
      end
    end

    private
    def check!(command, args)
      allowed(command).each do |checks|
        return if valid_args?(args, checks)
      end
      raise_invalid(command, args)
    end

    def valid_args?(args, checks)
      return false unless valid_length?(args, checks)
      check = nil
      args.each_with_index do |provided, i|
        check = checks[i] unless check == '**'
        return false unless match?(provided, check)
      end
      true
    end

    def valid_length?(args, checks)
      args.length == checks.length || checks.last == '**'
    end

    def match?(arg, check)
      check == '**' || check.is_a?(Regexp) && !!check.match(arg) || arg == check
    end

    def raise_invalid(command, args)
      raise "Invalid arguments for command \#{command}, " <<
        "provided args: \#{args.inspect}"
    end
  end
end

base = "/var/lib/lxc"
base_path = %r{\\A\#{base}/.*\\z}
templates_path = %r{\\A/usr/(share|lib|lib64|local/lib)/lxc/templates/.*\\z}
boxes_path = %r{\\A#{Regexp.escape(@env.boxes_path.to_s)}/.*\\z}
gems_path = %r{\\A#{Regexp.escape(@env.gems_path.to_s)}/.*\\z}
template_src = %r{\\A#{Vagrant::LXC.source_root.join('scripts/lxc-template').to_s}\\z}

##
# Commands from provider.rb
# - Check lxc is installed
Whitelist.add '/usr/bin/which', /\\Alxc-\\w+\\z/

##
# Commands from driver.rb
# - Container config file
Whitelist.add '/bin/cat', base_path
# - Shared folders
Whitelist.add '/bin/mkdir', '-p', base_path
# - Container config customizations and pruning
Whitelist.add '/bin/su', 'root', '-c', %r{\\A"sed -e '.*' -ibak \#{base}/.*/config"\\z}
Whitelist.add '/bin/su', 'root', '-c', %r{\\A"echo '.*' >> \#{base}/.*/config"\\z}
# - Template import
Whitelist.add '/bin/cp', boxes_path, templates_path
Whitelist.add '/bin/cp', gems_path, templates_path
Whitelist.add '/bin/cp', template_src, templates_path
Whitelist.add '/bin/chmod', '+x', templates_path
# - Template removal
Whitelist.add '/bin/rm', templates_path
# - Packaging
Whitelist.add '/bin/su', 'root', '-c', %r{\\A"cd \#{base}/.* && rm -f rootfs\.tar\.gz && tar --numeric-owner -czf /tmp/.*/rootfs\.tar\.gz -C \#{base}/.*/rootfs '\./\.'"\\z}
Whitelist.add '/bin/chown', /\\A\\d+:\\d+\\z/, %r{\\A/tmp/.*/rootfs\.tar\.gz\\z}

##
# Commands from driver/cli.rb
Whitelist.add '/usr/bin/lxc-version'
Whitelist.add '/usr/bin/lxc-ls'
Whitelist.add '/usr/bin/lxc-info', '--name', /.*/
Whitelist.add '/usr/bin/lxc-create', '--template', /.*/, '--name', /.*/, '**'
Whitelist.add '/usr/bin/lxc-destroy',  '--name', /.*/
Whitelist.add '/usr/bin/lxc-start', '-d', '--name', /.*/, '**'
Whitelist.add '/usr/bin/lxc-stop', '--name', /.*/
Whitelist.add '/usr/bin/lxc-shutdown', '--name', /.*/
Whitelist.add '/usr/bin/lxc-attach', '--name', /.*/, '**'
Whitelist.add '/usr/bin/lxc-attach', '-h'

##
# Commands from driver/action/remove_temporary_files.rb
Whitelist.add '/bin/rm', '-rf', %r{\\A\#{base}/.*/rootfs/tmp/.*}

# Watch out for stones
Whitelist.run!(ARGV)
            EOF
          end
          wrapper.close
          wrapper.path
        end

        # REFACTOR: Make use ERB rendering after https://github.com/mitchellh/vagrant/issues/3231
        #           lands into core
        def create_sudoers!(user, command)
          sudoers = Tempfile.new('vagrant-lxc-sudoers').tap do |file|
            file.puts "# Automatically created by vagrant-lxc"
            file.puts "Cmnd_Alias LXC = #{command}"
            file.puts "#{user} ALL=(root) NOPASSWD: LXC"
          end
          sudoers.close
          sudoers.path
        end

        def su_copy(files)
          commands = files.map { |file|
            [
              "rm -f #{file[:target]}",
              "cp #{file[:source]} #{file[:target]}",
              "chown root:root #{file[:target]}",
              "chmod #{file[:mode]} #{file[:target]}"
            ]
          }.flatten
          system "echo \"#{commands.join("; ")}\" | sudo sh"
        end
      end
    end
  end
end
