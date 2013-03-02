if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    # This can probably go away once we stop using vagrant as submodule
    add_filter { |source_file| source_file.filename =~ /\/vagrant\/plugins\// }
    add_filter { |source_file| source_file.filename =~ /\/vagrant\/lib\/vagrant(\/|\.rb)/ }
  end
end

require 'bundler/setup'

Bundler.require

require 'rspec-spies'

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
