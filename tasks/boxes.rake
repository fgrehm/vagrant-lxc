require 'rake/tasklib'

class BuildUbuntuBoxTask < ::Rake::TaskLib
  include ::Rake::DSL

  attr_reader :name

  def initialize(name, release, arch, opts = {})
    @name           = name
    @release        = release.to_s
    @arch           = arch.to_s
    @install_chef   = opts.fetch(:chef, true)
    @install_puppet = opts.fetch(:puppet, true)
    @file           = opts[:file] || default_box_file

    desc "Build an Ubuntu #{release} #{arch} box" unless ::Rake.application.last_comment
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

    if Dir.exists?('boxes/temp')
      puts "There is a partially built box under #{File.expand_path('./boxes/temp')}, please remove it before building a new box"
      exit 1
    end

    sh 'mkdir -p boxes/temp/'
    Dir.chdir 'boxes/temp' do
      sh "sudo ../ubuntu/download #{@arch} #{@release}"
      sh "sudo ../ubuntu/install-puppet" if @install_puppet
      sh "sudo ../ubuntu/install-chef" if @install_chef
      sh 'sudo rm -f rootfs.tar.gz'
      sh 'sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs/*'
      sh 'sudo rm -rf rootfs'
      sh "sudo chown #{ENV['USER']}:#{ENV['USER']} rootfs.tar.gz"
      sh "cp ../ubuntu/lxc-template ."
      metadata = File.read('../ubuntu/metadata.json.template')
      metadata.gsub!('ARCH', @arch)
      metadata.gsub!('RELEASE', @release)
      File.open('metadata.json', 'w') { |f| f.print metadata }
      sh "tar -czf tmp-package.box ./*"
    end

    sh "cp boxes/temp/tmp-package.box boxes/output/#{@file}"
    sh "rm -rf boxes/temp"
  end

  def default_box_file
    require 'time'
    "lxc-#{@release}-#{@arch}-#{Date.today}.box"
  end
end

namespace :boxes do
  namespace :ubuntu do
    namespace :build do
      chef   = ENV['CHEF'] != '0'
      puppet = ENV['PUPPET'] != '0'

      desc 'Build an Ubuntu Precise 64 bits box'
      BuildUbuntuBoxTask.new(:precise64, :precise, 'amd64', chef: chef, puppet: puppet)

      desc 'Build an Ubuntu Quantal 64 bits box'
      BuildUbuntuBoxTask.new(:quantal64, :quantal, 'amd64', chef: chef, puppet: puppet)

      # FIXME: Find out how to install chef on raring
      desc 'Build an Ubuntu Raring 64 bits box'
      BuildUbuntuBoxTask.new(:raring64, :raring, 'amd64', chef: false, puppet: puppet)
    end
  end
end
