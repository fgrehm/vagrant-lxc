require 'unit_helper'

require "vendored_vagrant"
require 'vagrant-lxc/container/cli'

describe Vagrant::LXC::Container::CLI do
  describe 'list' do
    let(:lxc_ls_out) { "dup-container\na-container dup-container" }
    let(:exec_args)  { @exec_args }
    let(:result)     { subject.list }

    before do
      Vagrant::Util::Subprocess.stub(:execute) { |*args|
        @exec_args = args
        stub(exit_code: 0, stdout: lxc_ls_out)
      }
    end

    it 'grabs previously created containers from lxc-ls' do
      result.should    be_an Enumerable
      result.should    include 'a-container'
      result.should    include 'dup-container'
      exec_args.should include 'lxc-ls'
    end

    it 'removes duplicates from lxc-ls output' do
      result.uniq.should == result
    end
  end
end
