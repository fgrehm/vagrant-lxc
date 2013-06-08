require 'pathname'
require 'rake/tasklib'
load 'tasks/boxes.v2.rake'

class BuildGenericBoxTaskV3 < BuildGenericBoxTaskV2
  def build
    check_if_box_has_been_built!

    FileUtils.mkdir_p 'boxes/temp' unless File.exist? 'base/temp'
    check_for_partially_built_box!

    pwd = Dir.pwd
    sh 'mkdir -p boxes/temp/'
    Dir.chdir 'boxes/temp' do
      download
      install_cfg_engines
      finalize
      prepare_package_contents pwd
      sh 'sudo rm -rf rootfs'
      sh "tar -czf tmp-package.box ./*"
    end

    sh 'mkdir -p boxes/output'
    sh "cp boxes/temp/tmp-package.box boxes/output/#{@file}"
    sh "rm -rf boxes/temp"
  end

  def finalize
    require 'vagrant'
    auth_key = Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
    run 'finalize', @arch, @release, auth_key
  end

  def prepare_package_contents(pwd)
    run 'cleanup'
    sh 'sudo rm -f rootfs.tar.gz'
    sh 'sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs/*'
    sh "sudo chown #{ENV['USER']}:#{`id -gn`.strip} rootfs.tar.gz"
    sh "cp #{pwd}/boxes/common/lxc-template ."
    sh "cp #{pwd}/boxes/common/lxc.conf ."
    sh "cp #{pwd}/boxes/common/metadata.json ."
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
