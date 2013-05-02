require 'rake/tasklib'

class BuildGenericBoxTask < ::Rake::TaskLib
  include ::Rake::DSL

  attr_reader :name

  def initialize(name, distrib, release, arch, opts = {})
    @name             = name
    @distrib          = distrib
    @release          = release.to_s
    @arch             = arch.to_s
    @install_chef     = opts.fetch(:chef, true)
    @install_puppet   = opts.fetch(:puppet, true)
    @install_babushka = opts.fetch(:babushka, true)
    @file             = opts[:file] || default_box_file

    desc "Build an #{distrib.upcase} #{release} #{arch} box" unless
      ::Rake.application.last_comment
    task name do
      RakeFileUtils.send(:verbose, true) do
        run_task
      end
    end
  end

  def run_task
    if File.exists?("./boxes/output/#{@file}")
      puts 'Box has been built already!'
      exit 1
    end

    if Dir.entries('boxes/temp').size > 2
      puts 'There is a partially built box under ' +
        File.expand_path('./boxes/temp') +
        ', please remove it before building a new box'
      exit 1
    end

    pwd = Dir.pwd
    sh 'mkdir -p boxes/temp/'
    Dir.chdir 'boxes/temp' do
      sh "sudo #{pwd}/boxes/#{@distrib}/download #{@arch} #{@release}"
      [ :puppet, :chef, :babushka ].each do |cfg_engine|
        next unless instance_variable_get :"@install_#{cfg_engine}"
        script_name = "install-#{cfg_engine}"
        install_path = File.join pwd, 'boxes', @distrib, script_name
        unless File.readable? install_path
          install_path = File.join pwd, 'boxes', 'common', script_name
        end
        if File.readable? install_path
          sh "sudo #{install_path}"
        else
          STDERR.puts "cannot execute #{install_path} (not found?)"
        end
      end
      sh 'sudo rm -f rootfs.tar.gz'
      sh 'sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs/*'
      sh 'sudo rm -rf rootfs'
      sh "sudo chown #{ENV['USER']}:#{ENV['USER']} rootfs.tar.gz"
      sh "cp #{pwd}/boxes/#{@distrib}/lxc-template ."
      metadata = File.read("#{pwd}/boxes/#{@distrib}/metadata.json.template")
      metadata.gsub!('ARCH', @arch)
      metadata.gsub!('RELEASE', @release)
      File.open('metadata.json', 'w') { |f| f.print metadata }
      sh "tar -czf tmp-package.box ./*"
    end

    sh 'mkdir -p boxes/output'
    sh "cp boxes/temp/tmp-package.box boxes/output/#{@file}"
    sh "rm -rf boxes/temp"
  end

  def default_box_file
    require 'time'
    "lxc-#{@release}-#{@arch}-#{Date.today}.box"
  end
end

class BuildDebianBoxTask < BuildGenericBoxTask
  def initialize(name, release, arch, opts = {})
    super(name, 'debian', release, arch, opts)
  end
end

class BuildUbuntuBoxTask < BuildGenericBoxTask
  def initialize(name, release, arch, opts = {})
    super(name, 'ubuntu', release, arch, opts)
  end
end

chef     = ENV['CHEF']     == '1'
puppet   = ENV['PUPPET']   == '1'
babushka = ENV['BABUSHKA'] == '1'

namespace :boxes do
  namespace :ubuntu do
    namespace :build do

      desc 'Build an Ubuntu Precise 64 bits box'
      BuildUbuntuBoxTask.
        new(:precise64,
            :precise, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

      desc 'Build an Ubuntu Quantal 64 bits box'
      BuildUbuntuBoxTask.
        new(:quantal64,
            :quantal, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

      # FIXME: Find out how to install chef on raring
      desc 'Build an Ubuntu Raring 64 bits box'
      BuildUbuntuBoxTask.
        new(:raring64,
            :raring, 'amd64', chef: false, puppet: puppet, babushka: babushka)
    end
  end

  namespace :debian do
    namespace :build do

      desc 'Build an Debian Wheezy 64 bits box'
      BuildDebianBoxTask.
        new(:wheezy64,
            :wheezy, 'amd64', chef: chef, puppet: puppet, babushka: babushka)

      desc 'Build an Debian Sid/unstable 64 bits box'
      BuildDebianBoxTask.
        new(:sid64,
            :sid, 'amd64', chef: chef, puppet: puppet, babushka: babushka)
    end
  end
end
