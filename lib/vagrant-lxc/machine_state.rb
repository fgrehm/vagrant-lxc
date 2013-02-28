module Vagrant
  module LXC
    class MachineState < Vagrant::MachineState
      CONTAINER_STATE_FILE_PATH = '/tmp/vagrant-lxc-container-state-%<id>s'
      CREATED_STATES            = %w( running poweroff ).map!(&:to_sym)

      def initialize(machine)
        @machine = machine
      end

      def id
        @id ||=
          begin
            state_id = nil
            state_id = :not_created if !@machine.id
            # TODO: Grab the real machine state here
            state_id = read_state_from_file if !state_id
            state_id = :unknown if !state_id
            state_id
          end
      end

      def short_description
        @short ||= self.id.to_s.gsub("_", " ")
      end

      def long_description
        @long ||= I18n.t("vagrant.commands.status.#{self.id}")
      end

      def created?
        CREATED_STATES.include?(self.id)
      end

      def off?
        self.id == :poweroff
      end

      def running?
        self.id == :running
      end

      def update!(state)
        return File.delete(state_file_path) if state.to_sym == :not_created
        File.open(state_file_path, 'w') { |f| f.print state }
      end

      def read_state_from_file
        if File.exists?(state_file_path)
          File.read(state_file_path).to_sym
        elsif @machine.id
          :unknown
        end
      end
      private :read_state_from_file

      def state_file_path
        @path ||= CONTAINER_STATE_FILE_PATH % {id: @machine.id}
      end
      private :state_file_path
    end
  end
end
