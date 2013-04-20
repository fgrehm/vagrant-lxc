if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.start { add_filter '/spec/' }
  SimpleCov.merge_timeout 300
end

require 'bundler/setup'

require 'i18n'

require 'rspec-spies'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

# If we should verify constant names, eager loads
if ENV['VERIFY_CONSTANT_NAMES']
  require 'vagrant-lxc/plugin'
  require 'vagrant-lxc/provider'
  require 'vagrant-lxc/config'
end

require 'rspec/fire'
RSpec::Fire.configure do |config|
  config.verify_constant_names = ENV['VERIFY_CONSTANT_NAMES'] == '1'
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
