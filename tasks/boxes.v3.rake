require 'pathname'
require 'rake/tasklib'
load 'tasks/boxes.v2.rake'

class BuildGenericBoxTaskV3 < BuildGenericBoxTaskV2
  def build
    # TODO: Build the base box and lxc-create it somehow
    super
  end
end

class BuildDebianBoxTaskV3 < BuildGenericBoxTaskV3
  def initialize(name, release, arch, opts = {})
    super(name, 'debian', release, arch, opts)
  end
end

class BuildUbuntuBoxTaskV3 < BuildGenericBoxTaskV3
  def initialize(name, release, arch, opts = {})
    super(name, 'ubuntu', release, arch, opts)
  end
end

chef     = ENV['CHEF']     == '1'
puppet   = ENV['PUPPET']   == '1'
babushka = ENV['BABUSHKA'] == '1'

namespace :boxes do
  namespace :v3 do
    namespace :ubuntu do
      namespace :build do

        desc 'Build an Ubuntu Precise 64 bits box'
        BuildUbuntuBoxTaskV3.
          new(:precise64,
              :precise, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

        desc 'Build an Ubuntu Quantal 64 bits box'
        BuildUbuntuBoxTaskV3.
          new(:quantal64,
              :quantal, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

        # FIXME: Find out how to install chef on raring
        desc 'Build an Ubuntu Raring 64 bits box'
        BuildUbuntuBoxTaskV3.
          new(:raring64,
              :raring, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

        desc 'Build all Ubuntu boxes'
        task :all => %w( precise64 quantal64 raring64 )
      end
    end

    # FIXME: Find out how to install chef on debian boxes
    namespace :debian do
      namespace :build do
        desc 'Build an Debian Squeeze 64 bits box'
        BuildDebianBoxTaskV3.
          new(:squeeze64,
              :squeeze, 'amd64', chef: false, puppet: puppet, babushka: babushka)

        desc 'Build an Debian Wheezy 64 bits box'
        BuildDebianBoxTaskV3.
          new(:wheezy64,
              :wheezy, 'amd64', chef: false, puppet: puppet, babushka: babushka)

        desc 'Build an Debian Sid/unstable 64 bits box'
        BuildDebianBoxTaskV3.
          new(:sid64,
              :sid, 'amd64', chef: false, puppet: puppet, babushka: babushka)

        desc 'Build all Debian boxes'
        task :all => %w( squeeze64 wheezy64 sid64 )
      end
    end

    desc 'Build all base boxes for release'
    task :build_all => %w( ubuntu:build:all debian:build:all )
  end
end
