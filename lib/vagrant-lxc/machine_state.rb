module Vagrant
  module LXC
    class MachineState < Vagrant::MachineState
      CREATED_STATES = %w( running poweroff ).map!(&:to_sym)

      def initialize(state_id)
        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("vagrant.commands.status.#{state_id}")
        super(state_id, short, long)
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
    end
  end
end
