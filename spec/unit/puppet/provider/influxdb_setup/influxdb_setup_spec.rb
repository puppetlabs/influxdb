# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::Influxdb')
ensure_module_defined('Puppet::Provider::InfluxdbSetup')
require 'puppet/provider/influxdb/influxdb'
require 'puppet/provider/influxdb_setup/influxdb_setup'

RSpec.describe Puppet::Provider::InfluxdbSetup::InfluxdbSetup do
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
    before(:each) do
      Puppet::Provider::Influxdb::Influxdb.influxdb_host = 'localhost'
      Puppet::Provider::Influxdb::Influxdb.influxdb_port = 8086
    end

    # rubocop:disable RSpec/SubjectStub
    context 'when not setup' do
      it 'processes resources' do
        allow(provider).to receive(:influx_get).with('/api/v2/setup').and_return({ 'allowed' => true })
        expect(provider.get(context)).to eq [
          {
            name: 'localhost',
            ensure: 'absent'
          },
        ]
      end

      context 'when setup' do
        it 'processes resources' do
          allow(provider).to receive(:influx_get).with('/api/v2/setup').and_return({ 'allowed' => false })
          expect(provider.get(context)).to eq [
            {
              name: 'localhost',
              ensure: 'present'
            },
          ]
        end
      end
    end
  end

  describe '#create' do
    it 'creates resources' do
      should = {
        bucket: 'puppet',
        org: 'puppetlabs',
        username: 'admin',
        password: RSpec::Puppet::Sensitive.new('puppetlabs'),
        token_file: '/tmp/foo',
        ensure: 'present'
      }
      should_unwrapped = {
        bucket: 'puppet',
        org: 'puppetlabs',
        username: 'admin',
        password: 'puppetlabs'
      }

      allow(provider).to receive(:influx_post).with('/api/v2/setup', JSON.dump(should_unwrapped)).and_return({ 'auth' => { 'token' => 'token' } })

      expect(context).to receive(:debug).with("Creating '/api/v2/setup' with #{should}")
      provider.create(context, '/api/v2/setup', should)
    end
  end

  describe '#update' do
    it 'does nothing' do
      expect(context).to receive(:warning).with('Unable to update setup resource')
      provider.update(context, nil, nil)
    end
  end

  describe '#delete' do
    it 'does nothing' do
      expect(context).to receive(:warning).with('Unable to delete setup resource')
      provider.delete(context, nil)
    end
  end
end
