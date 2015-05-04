require 'tempfile'

module Vagrant
  module LXC
    module Command
      class Sudoers < Vagrant.plugin("2", :command)

        def initialize(argv, env)
          super
          @argv
          @env = env
        end

        def execute
          options = { user: ENV['USER'] }

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc sudoers"
            opts.separator ""
            opts.on('-u user', '--user user', String, "The user for which to create the policy (defaults to '#{options[:user]}')") do |u|
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
          "/etc/sudoers.d/vagrant-lxc"
        end

        private

        # This requires vagrant 1.5.2+ https://github.com/mitchellh/vagrant/commit/3371c3716278071680af9b526ba19235c79c64cb
        def create_wrapper!
          wrapper = Tempfile.new('lxc-wrapper').tap do |file|
            template = Vagrant::Util::TemplateRenderer.new(
              'sudoers.rb',
              :template_root  => Vagrant::LXC.source_root.join('templates').to_s,
              :cmd_paths      => build_cmd_paths_hash,
              :pipework_regex => "\\A" + ( `which pipework`.to_s.strip[/.+/m] || "#{ENV['HOME']}/\\.vagrant\\.d/gems/gems/vagrant-lxc.+/scripts/pipework" )
            )
            file.puts template.render
          end
          wrapper.close
          wrapper.path
        end

        def create_sudoers!(user, command)
          sudoers = Tempfile.new('vagrant-lxc-sudoers').tap do |file|
            file.puts "# Automatically created by vagrant-lxc"
            file.puts "#{user} ALL=(root) NOPASSWD: #{command}"
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

        def build_cmd_paths_hash
          {}.tap do |hash|
            %w( which cat mkdir cp chown chmod rm tar chown ip ifconfig brctl ).each do |cmd|
              hash[cmd] = `which #{cmd}`.strip
            end
            hash['lxc_bin'] = Pathname(`which lxc-create`.strip).parent.to_s
            hash['ruby'] = Gem.ruby
          end
        end
      end
    end
  end
end
