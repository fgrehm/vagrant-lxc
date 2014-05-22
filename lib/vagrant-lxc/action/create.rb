module Vagrant
  module LXC
    module Action
      class Create
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::create")
        end

        def call(env)
          config = env[:machine].provider_config
          container_name = config.container_name

          case container_name
            when :machine
              container_name = env[:machine].name.to_s
            when String
              # Nothing to do here, move along...
            else
              container_name = "#{env[:root_path].basename}_#{env[:machine].name}"
              container_name.gsub!(/[^-a-z0-9_]/i, "")
              # make a copy of this variable for use in snapshot search later
              # milliseconds + random number suffix to allow for simultaneous
              # `vagrant up` of the same box in different dirs
              container_name << "_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          end

          # Treat btrfs as follows:
          # If a snapshot suffix is specified, search for a container name with that suffix
          # If no snapshot is found, look for the box to make a clone. 
          # If that is not found, setup the box to be cloned. 
          # Create the clone based on whatever snapshot was found
          if config.backingstore == "btrfs"
            all_containers = env[:machine].provider.driver.all_containers
            # Try to find a container based on a snapshot
            if !config.snapshot_suffix.nil? && config.existing_container_name.nil?
              snapshots_array = all_containers.select { |c|
                c =~ /#{env[:machine].name}_([0-9_]+)_lxcsnap_#{config.snapshot_suffix}/
              }
              if snapshots_array.empty?
                config.existing_container_name = nil
              else
                config.existing_container_name = snapshots_array.first
                @logger.info("Using snapshot #{config.existing_container_name}")
              end
            end
            # Can't find a snapshot, look for a box 
            if all_containers.include?(env[:machine].box.name) && config.existing_container_name.nil?
              config.existing_container_name = env[:machine].box.name
              @logger.info("Using snapshot #{config.existing_container_name}")
            end
            # if the backing store is btrfs and the box doesn't exist, we setup a clonable snapshot
            if config.existing_container_name.nil?
              @logger.info("No snapshots found. Creating a base snapshot from #{env[:machine].box.name}.")
              env[:machine].provider.driver.create(
                env[:machine].box.name,
                config.backingstore,
                config.backingstore_options,
                env[:lxc_template_src],
                env[:lxc_template_config],
                env[:lxc_template_opts]
              )
              config.existing_container_name = env[:machine].box.name
            end
            # Create the clone based off of whatever container we found
            @logger.debug("Making a clone from #{config.existing_container_name} to #{container_name}")
            env[:machine].provider.driver.clone(config.existing_container_name, container_name)
          else
            env[:machine].provider.driver.create(
              container_name,
              config.backingstore,
              config.backingstore_options,
              env[:lxc_template_src],
              env[:lxc_template_config],
              env[:lxc_template_opts]
            )
          end

          env[:machine].id = container_name

          @app.call env
        end
      end
    end
  end
end
