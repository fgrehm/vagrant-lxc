module UnitExampleGroup
  def self.included(base)
    base.metadata[:type] = :unit
    base.before do
      Object.any_instance.stub(:system) { |*args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      Object.any_instance.stub(:`) { |*args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
      require 'vagrant/util/subprocess'
      Vagrant::Util::Subprocess.stub(:execute) { |*args, &block|
        UnitExampleGroup.prevent_system_calls(*args, &block)
      }
    end
  end

  def self.prevent_system_calls(*args, &block)
    args.pop if args.last.is_a?(Hash)

    raise <<-MSG
Somehow your code under test is trying to execute a command on your system,
please stub it out or move your spec code to an acceptance spec.

Command: "#{args.join(' ')}"
    MSG
  end
end
