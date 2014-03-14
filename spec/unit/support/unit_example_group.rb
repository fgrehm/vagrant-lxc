module UnitExampleGroup
  def self.included(base)
    base.metadata[:type] = :unit
    base.before do
      allow_any_instance_of(Object).to receive(:system) { |instance, *args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      allow_any_instance_of(Object).to receive(:`) { |instance, *args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      allow_any_instance_of(Object).to receive(:exec) { |instance, *args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      allow_any_instance_of(Object).to receive(:fork) { |instance, *args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      allow_any_instance_of(Object).to receive(:spawn) { |instance, *args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      require 'vagrant/util/subprocess'
      allow(Vagrant::Util::Subprocess).to receive(:execute) { |*args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
    end
  end

  def self.prevent_system_calls(*args, &block)
    args.pop if args.last.is_a?(Hash)

    raise <<-MSG
Somehow your code under test is trying to execute a command on your system,
please stub it out or move your spec code to an acceptance spec.

Block:   #{block.inspect}
Command: "#{args.join(' ')}"
    MSG
  end
end
