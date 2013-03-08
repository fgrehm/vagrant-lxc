module Vagrant
  module LXC
    module Errors
      class ExecuteError < Vagrant::Errors::VagrantError
        error_key(:lxc_execute_error)
      end
      class TemplateFileMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_template_file_missing)
      end
    end
  end
end
