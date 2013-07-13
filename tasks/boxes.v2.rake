require 'pathname'
require 'rake/tasklib'

class BuildGenericBoxTaskV2 < ::Rake::TaskLib
  include ::Rake::DSL

  attr_reader :name

  def initialize(name, distrib, release, arch, opts = {})
    @name             = name
    @distrib          = distrib
    @release          = release.to_s
    @arch             = arch.to_s
    @install_chef     = opts.fetch(:chef, false)
    @install_puppet   = opts.fetch(:puppet, true)
    @install_babushka = opts.fetch(:babushka, true)
    @file             = opts[:file] || default_box_file
    @scripts_path     = Pathname(Dir.pwd).join('boxes')

    desc "Build an #{distrib.upcase} #{release} #{arch} box" unless
      ::Rake.application.last_comment
    task name do
      RakeFileUtils.send(:verbose, true) do
        build
      end
    end
  end

  def default_box_file
    require 'time'
    "lxc-#{@release}-#{@arch}-#{Date.today}.box"
  end

  def run(script_name, *args)
    unless (script = @scripts_path.join(@distrib, script_name)).readable?
      script = @scripts_path.join('common', script_name)
    end

    if script.readable?
      sh "sudo #{script} #{args.join(' ')}"
    else
      STDERR.puts "cannot execute #{script_name} (not found?)"
      exit 1
    end
  end

  def build
    check_if_box_has_been_built!

    FileUtils.mkdir_p 'boxes/temp' unless File.exist? 'base/temp'
    check_for_partially_built_box!

    pwd = Dir.pwd
    sh 'mkdir -p boxes/temp/'
    Dir.chdir 'boxes/temp' do
      download
      install_cfg_engines
      prepare_package_contents pwd
      sh 'sudo rm -rf rootfs'
      sh "tar -czf tmp-package.box ./*"
    end

    sh 'mkdir -p boxes/output'
    sh "cp boxes/temp/tmp-package.box boxes/output/#{@file}"
    sh "rm -rf boxes/temp"
  end

  def check_if_box_has_been_built!
    return unless File.exists?("./boxes/output/#{@file}")

    puts 'Box has been built already!'
    exit 1
  end

  def check_for_partially_built_box!
    return unless Dir.entries('boxes/temp').size > 2

    puts 'There is a partially built box under ' +
      File.expand_path('./boxes/temp') +
      ', please remove it before building a new box'
    exit 1
  end

  def download
    run 'download', @arch, @release
  end

  def install_cfg_engines
    [ :puppet, :chef, :babushka ].each do |cfg_engine|
      next unless instance_variable_get :"@install_#{cfg_engine}"
      script_name = "install-#{cfg_engine}"
      run script_name
    end
  end

  def prepare_package_contents(pwd)
    run 'cleanup'
    sh 'sudo rm -f rootfs.tar.gz'
    sh 'sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs/*'
    sh "sudo chown #{ENV['USER']}:#{`id -gn`.strip} rootfs.tar.gz"
    sh "cp #{pwd}/boxes/#{@distrib}/lxc-template ."
    compile_metadata(pwd)
  end

  def compile_metadata(pwd)
    metadata = File.read("#{pwd}/boxes/#{@distrib}/metadata.json.template")
    metadata.gsub!('ARCH', @arch)
    metadata.gsub!('RELEASE', @release)
    File.open('metadata.json', 'w') { |f| f.print metadata }
  end
end

class BuildDebianBoxTaskV2 < BuildGenericBoxTaskV2
  def initialize(name, release, arch, opts = {})
    super(name, 'debian', release, arch, opts)
  end
end

class BuildUbuntuBoxTaskV2 < BuildGenericBoxTaskV2
  def initialize(name, release, arch, opts = {})
    super(name, 'ubuntu', release, arch, opts)
  end
end

chef     = ENV['CHEF']     == '1'
puppet   = ENV['PUPPET']   == '1'
babushka = ENV['BABUSHKA'] == '1'

namespace :boxes do
  namespace :v2 do
    namespace :ubuntu do
      namespace :build do

        desc 'Build an Ubuntu Precise 64 bits box'
        BuildUbuntuBoxTaskV2.
          new(:precise64,
              :precise, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

        desc 'Build an Ubuntu Quantal 64 bits box'
        BuildUbuntuBoxTaskV2.
          new(:quantal64,
              :quantal, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

        # FIXME: Find out how to install chef on raring
        desc 'Build an Ubuntu Raring 64 bits box'
        BuildUbuntuBoxTaskV2.
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
        BuildDebianBoxTaskV2.
          new(:squeeze64,
              :squeeze, 'amd64', chef: false, puppet: puppet, babushka: babushka)

        desc 'Build an Debian Wheezy 64 bits box'
        BuildDebianBoxTaskV2.
          new(:wheezy64,
              :wheezy, 'amd64', chef: false, puppet: puppet, babushka: babushka)

        desc 'Build an Debian Sid/unstable 64 bits box'
        BuildDebianBoxTaskV2.
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
