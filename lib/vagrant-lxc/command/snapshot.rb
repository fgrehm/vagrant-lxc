require 'tempfile'
require "vagrant-lxc/provider"

module Vagrant
  module LXC
    module Command
      class Snapshot < Vagrant.plugin("2", :command)

        def initialize(argv, env)
          super
          @argv
          @env = env
        end

        def execute
          options = { user: ENV['USER'], snapshot_suffix: "" }

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc -s snapshot_suffix. Note that this will halt all the containers."
            opts.separator ""
            opts.on('-s snapshot_suffix', '--snapshot_suffix snapshot', String, "The snapshot suffix.") do |o|
              options[:snapshot_suffix] = o
            end
          end

          argv = parse_options(opts)
          return unless argv 
          if options[:snapshot_suffix].empty?
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          with_target_vms(argv) do |machine|
            machine.action(:halt, :force_halt => true)
            container_name=machine.provider.driver.container_name.to_s
            snapshot_name = container_name + "_lxcsnap_" + options[:snapshot_suffix]
            if machine.provider.driver.all_containers.include?(snapshot_name)
              raise Vagrant::Errors::SnapshotAlreadyExists, name: @name
            end
            machine.provider.driver.clone(tmp_name, snapshot_name)
          end
        end
      end
    end
  end
end
