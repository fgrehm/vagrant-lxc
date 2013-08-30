require 'time'
require 'pathname'
require 'rake/tasklib'

class BuildGenericBoxTask < ::Rake::TaskLib
  include ::Rake::DSL

  attr_reader :name

  def initialize(name, distrib, release, arch, cfg_engines)
    @name         = name
    @distrib      = distrib
    @release      = release.to_s
    @arch         = arch.to_s
    @cfg_engines  = cfg_engines
    @file         = "lxc-#{@release}-#{@arch}-#{Date.today}.box"
    @scripts_path = Pathname(Dir.pwd).join('boxes')

    task name do
      RakeFileUtils.send(:verbose, true) do
        build
      end
    end
  end

  def run(script_name, *args)
    script = @scripts_path.join('common', script_name)
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

    import_template do |template|
      create_base_container(template) do |rootfs|
        configure_vagrant_user(rootfs)
        install_cfg_engines(rootfs)
        cleanup(rootfs)
        prepare_package_contents(rootfs)
        compress_box(rootfs)
      end
    end
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

  def create_base_container(template)
    container_name = 'vagrant-base-box-tmp'
    sh "sudo lxc-create -n #{container_name} -t vagrant-base-box-template -- --arch #{@arch} --release #{@release}"
    yield "/var/lib/lxc/#{container_name}/rootfs"
  ensure
    sh "sudo lxc-destroy -n #{container_name}"
  end

  def configure_vagrant_user(rootfs)
    puts "TODO: Configure vagrant user under #{rootfs}"
  end

  def install_cfg_engines(rootfs)
    puts "TODO: Install cfg engines under #{rootfs}"
  end

  def prepare_package_contents(rootfs)
    puts "TODO: Prepare pkg contents under #{rootfs}"
  end

  def compress_box(rootfs)
    puts "TODO: Compress base box under #{rootfs}"
  end

  def cleanup(rootfs)
    puts "TODO: Cleanup under #{rootfs}"
  end

  def import_template
    template_name     = "vagrant-base-box-template"
    tmp_template_path = templates_path.join("lxc-#{template_name}")
    src               = "./boxes/templates/#{@distrib}"

    sh "sudo cp #{src} #{tmp_template_path}"

    yield template_name
  ensure
    sh "sudo rm #{tmp_template_path}" if tmp_template_path.file?
  end

  TEMPLATES_PATH_LOOKUP = %w(
    /usr/share/lxc/templates
    /usr/lib/lxc/templates
    /usr/lib64/lxc/templates
    /usr/local/lib/lxc/templates
  )
  def templates_path
    return @templates_path if @templates_path

    path = TEMPLATES_PATH_LOOKUP.find { |candidate| File.directory?(candidate) }
    raise 'Unable to identify lxc templates path!' unless path

    @templates_path = Pathname(path)
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

cfg_engines = {
  puppet:   ENV['PUPPET']   == '1',
  babushka: ENV['BABUSHKA'] == '1',
  salt:     ENV['SALT']     == '1',
  chef:     ENV['CHEF']     == '1'
}

namespace :boxes do
  namespace :ubuntu do
    namespace :build do

      desc 'Build an Ubuntu Precise 64 bits box'
      BuildUbuntuBoxTask.new(:precise64, :precise, 'amd64', cfg_engines)

      desc 'Build an Ubuntu Quantal 64 bits box'
      BuildUbuntuBoxTask.new(:quantal64, :quantal, 'amd64', cfg_engines)

      desc 'Build an Ubuntu Raring 64 bits box'
      BuildUbuntuBoxTask.new(:raring64, :raring, 'amd64', cfg_engines)

      desc 'Build an Ubuntu Saucy 64 bits box'
      BuildUbuntuBoxTask.new(:saucy64, :saucy, 'amd64', cfg_engines)

      desc 'Build all Ubuntu boxes'
      task :all => %w( precise64 quantal64 raring64 saucy64 )
    end
  end

  namespace :debian do
    %w( chef salt).each { |cfg| cfg_engines.delete(cfg.to_sym) }
    namespace :build do
      desc 'Build an Debian Squeeze 64 bits box'
      BuildDebianBoxTask.new(:squeeze64, :squeeze, 'amd64', cfg_engines)

      desc 'Build an Debian Wheezy 64 bits box'
      BuildDebianBoxTask.new(:wheezy64, :wheezy, 'amd64', cfg_engines)

      desc 'Build an Debian Sid/unstable 64 bits box'
      BuildDebianBoxTask.new(:sid64, :sid, 'amd64', cfg_engines)

      desc 'Build all Debian boxes'
      task :all => %w( squeeze64 wheezy64 sid64 )
    end
  end

  desc 'Build all base boxes for release'
  task :build_all => %w( ubuntu:build:all debian:build:all )
end
