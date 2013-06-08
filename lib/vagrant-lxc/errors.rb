require 'vagrant/errors'

module Vagrant
  module LXC
    module Errors
      class ExecuteError < Vagrant::Errors::VagrantError
        error_key(:lxc_execute_error)
      end

      # Box related errors
      class TemplateFileMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_template_file_missing)
      end
      class RootFSTarballMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_invalid_box_version)
      end
      class IncompatibleBox < Vagrant::Errors::VagrantError
        error_key(:lxc_incompatible_box)
      end
    end
  end
end
