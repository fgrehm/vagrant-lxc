require 'spec_helper'

Dir[File.dirname(__FILE__) + "/unit/support/**/*.rb"].each { |f| require f }

if defined? SimpleCov
  SimpleCov.command_name 'unit'
end

RSpec.configure do |config|
  config.include RSpec::Fire

  config.include UnitExampleGroup, :type => :unit, :example_group => {
    :file_path => /\bspec\/unit\//
  }
end
