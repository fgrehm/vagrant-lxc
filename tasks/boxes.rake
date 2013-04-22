require 'rake/tasklib'

class BuildUbuntuBoxTask < ::Rake::TaskLib
  include ::Rake::DSL

  attr_reader :name

  def initialize(name, release, arch, opts = {})
    @name    = name
    @release = release
    @arch    = arch
    @chef    = opts[:chef]
    @puppet  = opts[:puppet]
    @file    = opts[:file] || "lxc-#{@release}-#{@arch}.box"

    desc "Build an Ubuntu #{release} #{arch} box" unless ::Rake.application.last_comment
    task name do
      RakeFileUtils.send(:verbose, true) do
        run_task
      end
    end
  end

  def run_task
    puts "./boxes/output/#{@file}"
    if File.exists?("./boxes/output/#{@file}")
      puts 'Box has been built already!'
      exit 1
    end

    sh 'mkdir -p boxes/temp/'
    Dir.chdir 'boxes/temp' do
      sh "sudo ../ubuntu/download #{@arch} #{@release}"
      sh "sudo ../ubuntu/install-puppet"
      sh "sudo ../ubuntu/install-chef"
      #sh 'rm -f rootfs.tar.gz'
      #sh 'sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs/*'
      #sh 'sudo rm -rf rootfs'
      #sh "sudo chown #{ENV['USER']}:#{ENV['USER']} rootfs.tar.gz && tar -czf tmp-package.box ./*"
    end
  end
end

namespace :boxes do
  namespace :ubuntu do
    namespace :build do
      desc 'Build an Ubuntu Quantal 64 bits box with puppet and chef installed'
      BuildUbuntuBoxTask.new(:quantal64, :quantal, 'amd64')

      desc 'Build an Ubuntu Raring 64 bits box with puppet and chef installed'
      BuildUbuntuBoxTask.new(:raring64, :raring, 'amd64')
    end
  end
end
