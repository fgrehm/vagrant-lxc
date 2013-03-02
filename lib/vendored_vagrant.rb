# Tks to: https://github.com/carlhuda/bundler/blob/master/lib/bundler/vendored_thor.rb

if defined?(Vagrant) && Vagrant.respond_to?(:in_installer?)
  puts "vagrant has already been required. This may cause vagrant-lxc to malfunction in unexpected ways."
end
vendor = File.expand_path('../../vendor/vagrant/lib', __FILE__)
$:.unshift(vendor) unless $:.include?(vendor)

require 'vagrant'
