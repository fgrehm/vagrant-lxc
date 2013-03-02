module Vagrant
  module LXC
    module Errors
      class ExecuteError < Vagrant::Errors::VagrantError
        error_key(:lxc_execute_error)
      end
    end
  end
end
