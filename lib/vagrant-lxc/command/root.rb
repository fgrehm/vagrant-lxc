module Vagrant
  module LXC
    module Command
      class Root < Vagrant.plugin("2", :command)
        def self.synopsis
          'LXC setup'
        end

        def initialize(argv, env)
          @args, @sub_command, @sub_args = split_main_and_subcommand(argv)
          @subcommands = Vagrant::Registry.new.tap do |registry|
            registry.register(:sudoers) do
              require_relative 'sudoers'
              Sudoers
            end
          end
          super(argv, env)
        end

        def execute
          # Print the help
          return help if @args.include?("-h") || @args.include?("--help")

          klazz = @subcommands.get(@sub_command.to_sym) if @sub_command
          return help unless klazz

          @logger.debug("Executing command: #{klazz} #{@sub_args.inspect}")

          # Initialize and execute the command class
          klazz.new(@sub_args, @env).execute
        end

        def help
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc <subcommand> [<args>]"
            opts.separator ""
            opts.separator "Available subcommands:"

            # https://github.com/mitchellh/vagrant/commit/4194da19c60956f6e59239c0145f772be257e79d
            keys = []
            @subcommands.each { |key, value| keys << key }

            keys.sort.each do |key|
              opts.separator "    #{key}"
            end

            opts.separator ""
            opts.separator "For help on any individual subcommand run `vagrant lxc <subcommand> -h`"
          end

          @env.ui.info(opts.help, :prefix => false)
        end

      end
    end
  end
end
