require 'vagrant/errors'

module Vagrant
  module LXC
    module Errors
      class ExecuteError < Vagrant::Errors::VagrantError
        error_key(:lxc_execute_error)
        attr_reader :stderr, :stdout, :exitcode
        def initialize(message, *args)
          super
          if message.is_a?(Hash)
            @stderr = message[:stderr]
            @stdout = message[:stdout]
            @exitcode = message[:exitcode]
          end
        end
      end

      # Raised when user interrupts a subprocess
      class SubprocessInterruptError < Vagrant::Errors::VagrantError
        error_key(:lxc_interrupt_error)
        def initialize(message, *args)
          super
        end
      end


      class LxcLinuxRequired < Vagrant::Errors::VagrantError
        error_key(:lxc_linux_required)
      end

      class LxcNotInstalled < Vagrant::Errors::VagrantError
        error_key(:lxc_not_installed)
      end

      class ContainerAlreadyExists < Vagrant::Errors::VagrantError
        error_key(:lxc_container_already_exists)
      end

      class CommandNotSupported < Vagrant::Errors::VagrantError
        error_key(:lxc_command_not_supported)
      end

      # Box related errors
      class TemplateFileMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_template_file_missing)
      end
      class TemplatesDirMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_templates_dir_missing)
      end
      class RootFSTarballMissing < Vagrant::Errors::VagrantError
        error_key(:lxc_invalid_box_version)
      end
      class IncompatibleBox < Vagrant::Errors::VagrantError
        error_key(:lxc_incompatible_box)
      end
      class RedirNotInstalled < Vagrant::Errors::VagrantError
        error_key(:lxc_redir_not_installed)
      end
    end
  end
end
