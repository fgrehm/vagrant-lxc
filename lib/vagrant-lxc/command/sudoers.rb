require 'tempfile'

module Vagrant
  module LXC
    module Command
      class Sudoers < Vagrant.plugin("2", :command)
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

          filename = "vagrant-lxc-#{options[:user]}"
          to_sudoers!(create_tempfile!(options[:user], filename), filename)
        end

        private

        # REFACTOR: Make use ERB rendering after https://github.com/mitchellh/vagrant/issues/3231
        #           lands into core
        def create_tempfile!(user, filename)
          sudoers = Tempfile.new(filename).tap do |file|
            file.write "# Automatically created by vagrant-lxc\n"
            commands.each do |command|
              file.write sudoers_policy(user, command[:cmd], command[:args])
            end
          end
          sudoers.close
          File.chmod(0644, sudoers.path)
          sudoers.path
        end

        def to_sudoers!(source, destination)
          destination = "/etc/sudoers.d/#{destination}"
          commands = [
            "rm -f #{destination}",
            "cp #{source} #{destination}",
            "chmod 440 #{destination}"
          ]
          `echo "#{commands.join('; ')}" | sudo sh`
        end

        def sudoers_policy(user, command, args)
          vagrant_home = "#{`echo ~#{user}`.chomp}/.vagrant.d"
          args = args.gsub /%\{VAGRANT_D\}/, vagrant_home
          args = args.gsub /%\{BOXES\}/, "#{vagrant_home}/boxes"
          "#{user} ALL=(root) NOPASSWD: #{command} #{args}\n"
        end

        def commands
         [
           { cmd: '/usr/bin/lxc-ls',        args: '' },
           { cmd: '/usr/bin/lxc-info',      args: '' },
           { cmd: '/usr/bin/lxc-attach',    args: '' },
           { cmd: '/usr/bin/which',         args: 'lxc-*' },
           { cmd: '/bin/cat',               args: '/var/lib/lxc/*' },
           { cmd: '/bin/mkdir',             args: '-p /var/lib/lxc/*' },
           { cmd: '/bin/su',                args: "root -c sed -e '*' -ibak /var/lib/lxc/*" },
           { cmd: '/bin/su',                args: "root -c echo '*' >> /var/lib/lxc/*" },
           { cmd: '/usr/bin/lxc-start',     args: '-d --name *' },
           { cmd: '/bin/cp',                args: '%{BOXES}/*/lxc/lxc-template /usr/lib/lxc/templates/*' },
           { cmd: '/bin/cp',                args: '%{VAGRANT_D}/gems/gems/vagrant-lxc-*/scripts/lxc-template /usr/lib/lxc/templates/*' },
           { cmd: '/bin/cp',                args: '%{BOXES}/*/lxc/lxc-template /usr/share/lxc/templates/*' },
           { cmd: '/bin/cp',                args: '%{VAGRANT_D}/gems/gems/vagrant-lxc-*/scripts/lxc-template /usr/share/lxc/templates/*' },
           { cmd: '/bin/rm',                args: '/usr/lib/lxc/templates/*' },
           { cmd: '/bin/rm',                args: '/usr/share/lxc/templates/*' },
           { cmd: '/bin/chmod',             args: '+x /usr/lib/lxc/*' },
           { cmd: '/bin/chmod',             args: '+x /usr/share/lxc/*' },
           { cmd: '/usr/bin/lxc-create',    args: '--template * --name * -- --tarball %{BOXES}/*' },
           { cmd: '/bin/rm',                args: '-rf /var/lib/lxc/*/rootfs/tmp/*' },
           { cmd: '/usr/bin/lxc-shutdown',  args: '--name *' },
           { cmd: '/usr/bin/lxc-stop',      args: '--name *' },
           { cmd: '/usr/bin/lxc-destroy',   args: '--name *' }
         ]
        end
      end
    end
  end
end
