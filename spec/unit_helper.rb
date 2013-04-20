require 'spec_helper'

if defined? SimpleCov
  SimpleCov.command_name 'unit'
end

RSpec.configure do |config|
  config.include RSpec::Fire

  config.include UnitExampleGroup, :type => :unit, :example_group => {
    :file_path => /\bspec\/unit\//
  }
end
