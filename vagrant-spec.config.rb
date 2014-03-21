# FIXME: Figure out why this doesn't work
if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.start { add_filter '/spec/' }
  SimpleCov.command_name 'acceptance'
end

if ENV['BOX_PATH'] == nil
  latest     = ENV.fetch('LATEST_BOXES','2014-03-21')
  release    = ENV.fetch('RELEASE', 'acceptance')
  local_path ="#{File.expand_path("../", __FILE__)}/boxes/output/#{latest}/vagrant-lxc-#{release}-amd64.box"
  if File.exists?(local_path)
    ENV['BOX_PATH'] = local_path
  else
    raise 'Set $BOX_PATH to the latest released boxes'
  end
end

Vagrant::Spec::Acceptance.configure do |c|
  c.component_paths << "spec/acceptance"
  c.provider 'lxc', box: ENV['BOX_PATH'], features: ['!suspend']
end
