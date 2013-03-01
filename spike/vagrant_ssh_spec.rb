require 'spec_helper'

describe 'vagrant ssh' do
  let(:ip) { '10.0.3.100' }

  before :all do
    destroy_container!
    configure_box_with :forwards => [[2222, 22]], :ip => ip
    provider_up
  end

  after :all do
    restore_rinetd_conf!
    destroy_container!
  end

  it 'accepts a user argument' do
    provider_ssh('c' => 'echo $USER', 'u' => 'ubuntu').should include 'ubuntu'
  end
end
