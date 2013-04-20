require 'spec_helper'

if defined? SimpleCov
  SimpleCov.command_name 'acceptance'
end

require 'vagrant'
require 'vagrant-lxc'

# RSpec.configure do |config|
#   config.include AcceptanceExampleGroup, :type => :unit, :example_group => {
#     :file_path => /\bspec\/unit\//
#   }
# end
