# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/influxdb'

RSpec.describe 'the influxdb type' do
  it 'loads' do
    expect(Puppet::Type.type(:influxdb)).not_to be_nil
  end
end
