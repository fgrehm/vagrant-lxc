require 'rubygems'

require 'bundler/setup'

Bundler.require

require 'yaml'
require 'shellwords'

`mkdir -p tmp`

module TestHelpers
  def provider_up
    `cd tmp && ../lib/provider up -o /vagrant/tmp/logger.log`
  end

  def destroy_container!
    `cd tmp && ../lib/provider destroy -o /vagrant/tmp/logger.log`
    `rm -f tmp/config.yml`
  end

  def restore_rinetd_conf!
    `sudo cp /vagrant/cache/rinetd.conf /etc/rinetd.conf`
    `sudo service rinetd restart`
  end

  def configure_box_with(opts)
    opts = opts.dup
    opts.keys.each do |key|
      opts[key.to_s] = opts.delete(key)
    end
    File.open('./tmp/config.yml', 'w') { |f| f.puts YAML::dump(opts) }
  end

  def provider_ssh(options)
    options = options.map { |opt, val| "-#{opt} #{Shellwords.escape val}" }
    options = options.join(' ')
    `cd tmp && ../lib/provider ssh #{options}`
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include TestHelpers

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.after :all do
    destroy_container!
    restore_rinetd_conf!
  end
end
