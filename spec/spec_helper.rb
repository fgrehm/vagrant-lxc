if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.start { add_filter '/spec/' }
  SimpleCov.merge_timeout 300
end

require 'bundler/setup'

require 'i18n'

require 'vagrant-lxc'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

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
