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
          options = { user: ENV['USER'], snapshot_suffix: "", snapshot_list: false }

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc -s snapshot_suffix. Note that this will halt all the containers."
            opts.separator ""
            opts.on('-s snapshot_suffix', '--snapshot_suffix snapshot', String, "The snapshot suffix.") do |o|
              options[:snapshot_suffix] = o
            end
            opts.on('-l', '--list', String, "List snapshots") do |o|
              options[:snapshot_list] = true
            end
          end

          argv = parse_options(opts)
          return unless argv

          if options[:snapshot_list]
            list_snapshots
            return
          end

          if options[:snapshot_suffix].empty?
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          else
            create_snapshot(options[:snapshot_suffix])
          end

        end

        def list_snapshots
          with_target_vms do |machine|
            snapshot_list=machine.provider.driver.all_containers.grep(/^s_/)
            snapshot_names = []
            snapshot_list.each do |m|
              t = m.match(/s_(.*)_(.*)/)
              snapshot_names << "#{t[1]}_#{t[2]}" if t
            end
            snapshot_names.uniq!
            puts snapshot_names
            break
          end
        end

        def create_snapshot(snapshot_suffix)
          with_target_vms do |machine|
            machine.action(:halt, :force_halt => true)
            container_name=machine.provider.driver.container_name.to_s
            snapshot_name = "s_#{machine.name}_#{snapshot_suffix}"
            if machine.provider.driver.all_containers.include?(snapshot_name)
              raise Vagrant::Errors::SnapshotAlreadyExists, name: snapshot_name
            end
            if machine.state.id == :not_created
              puts "Snapshot of #{machine.name} is not possible"
            else
              machine.provider.driver.clone(container_name, snapshot_name)
            end
          end
        end
      end
    end
  end
end
