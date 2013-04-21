require 'spec_helper'

unless ENV['USER'] == 'vagrant'
  puts 'Acceptance specs are supposed to run from one of the vagrant-lxc dev machines'
  exit 1
end

if defined? SimpleCov
  SimpleCov.command_name 'acceptance'
end

require 'vagrant'
require 'vagrant-lxc'

Dir[File.dirname(__FILE__) + "/acceptance/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include AcceptanceExampleGroup, :type => :acceptance, :example_group => {
    :file_path => /\bspec\/acceptance\//
  }
end
