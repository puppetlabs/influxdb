# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Influxdb')
require 'puppet/provider/influxdb/influxdb'

RSpec.describe Puppet::Provider::Influxdb::Influxdb do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      name: {
        type: 'String',
      },
      is_setup: {
        type: 'Boolean',
      },
      manage_setup: {
        type: 'Boolean',
      },
    }
  end

  let(:setup_api_response) do
    { allowed: true }
  end

  describe '#get' do
    it 'processes resources' do
      # allow(provider).to receive(:influx_get).and_return(setup_api_response)
      expect(context).to receive(:debug).with('Returning pre-canned example data')
      expect(provider.get(context)).to eq [
        {
          name: 'initial_setup',
          ensure: 'absent'
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

      provider.update(context, 'foo', name: 'foo', ensure: 'present')
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end
end
