module Vagrant
  module LXC
    class Container
      CONTAINER_STATE_FILE_PATH = '/tmp/vagrant-lxc-container-state-%<id>s'

      def initialize(machine)
        @machine = machine
      end

      def create
        puts 'TODO: Create container'
      end

      def start
        puts 'TODO: Start container'
        update!(:running)
      end

      def halt
        update!(:poweroff)
      end

      def destroy
        puts "TODO: Destroy container"
        File.delete(state_file_path) if state_file_path
      end

      def state
        # TODO: Grab the real machine state here
        read_state_from_file
      end

      private

      def update!(state)
        File.open(state_file_path, 'w') { |f| f.print state }
      end

      def read_state_from_file
        if File.exists?(state_file_path)
          File.read(state_file_path).to_sym
        elsif @machine.id
          :unknown
        end
      end

      def state_file_path
        CONTAINER_STATE_FILE_PATH % {id: @machine.id}
      end
    end
  end
end
