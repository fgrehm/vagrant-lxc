require 'spec_helper'

unless ENV['USER'] == 'vagrant'
  puts 'Acceptance specs are supposed to run from one of the vagrant dev machines'
  exit 1
end

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
