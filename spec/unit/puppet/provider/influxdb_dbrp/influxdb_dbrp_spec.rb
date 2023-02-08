# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::InfluxdbDbrp')
require 'puppet/provider/influxdb_dbrp/influxdb_dbrp'
require_relative '../../../../../lib/puppet_x/puppetlabs/influxdb/influxdb'
include PuppetX::Puppetlabs::PuppetlabsInfluxdb

RSpec.describe Puppet::Provider::InfluxdbDbrp::InfluxdbDbrp do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      name: {
        type: 'String',
      },
      bucket: {
        type: 'String',
      },
      org: {
        type: 'String',
      },
      is_default: {
        type: 'Optional[Boolean]',
      },
      rp: {
        type: 'String',
      }
    }
  end

  let(:bucket_response) do
    [{
      'links' => {
        'self' => '/api/v2/buckets?descending=false&limit=20&offset=0'
      },
      'buckets' => [
        {
          'id' => '12345',
          'orgID' => '123',
          'type' => 'user',
          'name' => 'puppet_data',
          'links' => {
            'self' => '/api/v2/buckets/12345',
          },
          'retentionRules' => [
            {
              'type' => 'expire',
              'everySeconds' => 2_592_000,
              'shardGroupDurationSeconds' => 604_800
            },
          ],
          'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
        },
      ]
    }]
  end

  let(:org_response) do
    [{
      'links' => {
        'self' => '/api/v2/orgs'
      },
      'orgs' => [
        {
          'id' => '123',
          'name' => 'puppetlabs',
          'links' => {
            'self' => '/api/v2/orgs/123',
          },
        },
      ]
    }]
  end

  let(:dbrp_response) do
    [{
      'content' => [
        {
          'id' => '1234567',
          'database' => 'puppet_data',
          'retention_policy' => 'Forever',
          'default' => true,
          'orgID' => '123',
          'bucketID' => '12345'
        },
      ]
    }]
  end

  describe '#get' do
    context 'with bucket resources' do
      # rubocop:disable RSpec/SubjectStub
      it 'processes resources' do
        provider.instance_variable_set('@use_ssl', true)
        provider.instance_variable_set('@host', 'foo.bar.com')
        provider.instance_variable_set('@port', 8086)
        provider.instance_variable_set('@token_file', '/root/.influxdb_token')
        provider.instance_variable_set('@token', RSpec::Puppet::Sensitive.new('puppetlabs'))

        allow(provider).to receive(:influx_get).with('/api/v2/orgs').and_return(org_response)
        allow(provider).to receive(:influx_get).with('/api/v2/dbrps?orgID=123').and_return(dbrp_response)
        allow(provider).to receive(:influx_get).with('/api/v2/buckets').and_return(bucket_response)

        should_hash = [{
          bucket: 'puppet_data',
          ensure: 'present',
          use_ssl: true,
          host: 'foo.bar.com',
          port: 8086,
          token: RSpec::Puppet::Sensitive.new('puppetlabs'),
          token_file: '/root/.influxdb_token',
          is_default: true,
          name: 'puppet_data',
          org: 'puppetlabs',
          rp: 'Forever',
        }]

        expect(provider.get(context)).to eq should_hash
      end
    end
  end

  describe '#create' do
    it 'creates resources' do
      should_hash = {
        bucket: 'puppet_data',
        ensure: 'present',
        is_default: true,
        name: 'puppet_data',
        org: 'puppetlabs',
        rp: 'Forever',
      }

      post_args = {
        bucketID: 12_345,
        database: 'puppet_data',
        org: 'puppetlabs',
        retention_policy: 'Forever',
        default: true
      }

      provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
      provider.instance_variable_set('@bucket_hash', [{ 'name' => 'puppet_data', 'id' => 12_345 }])
      provider.instance_variable_set(
        '@dbrp_hash',
        {
          "content": [
            {
              "id": '123',
              "database": 'puppet_data',
              "retention_policy": 'Forever',
              "default": true,
              "orgID": '123',
              "bucketID": '12345'
            },
          ]
        },
      )

      expect(provider).to receive(:influx_post).with(
        '/api/v2/dbrps?org=puppetlabs',
        JSON.dump(post_args),
      )

      expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")
      provider.create(context, should_hash[:name], should_hash)
    end
  end

  describe '#update' do
    let(:should_hash) do
      {
        bucket: 'puppet_data',
        ensure: 'present',
        is_default: false,
        name: 'puppet_data',
        org: 'puppetlabs',
        rp: 'Forever',
      }
    end

    it 'updates resources' do
      provider.instance_variable_set(
        '@dbrp_hash',
        [
          {
            'id' => '321',
            'database' => 'puppet_data',
            'retention_policy' => 'Forever',
            'default' => true,
            'orgID' => '123',
            'bucketID' => '12345',
            'name' => 'puppet_data'
          },
        ],
      )

      patch_args = ['/api/v2/dbrps/321?org=puppetlabs', JSON.dump({ default: should_hash[:is_default], retention_policy: should_hash[:rp] })]

      expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
      expect(provider).to receive(:influx_patch).with(*patch_args)

      provider.update(context, should_hash[:name], should_hash)
    end
  end

  describe '#delete' do
    it 'deletes resources' do
      provider.instance_variable_set(
        '@dbrp_hash',
        [
          {
            'id' => '321',
            'database' => 'puppet_data',
            'retention_policy' => 'Forever',
            'default' => true,
            'orgID' => '123',
            'bucketID' => '12345',
            'name' => 'puppet_data'
          },
        ],
      )

      provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
      provider.instance_variable_set('@bucket_hash', [{ 'name' => 'puppet_data', 'id' => 12_345 }])

      should_hash = {
        ensure: 'absent',
        name: 'puppet_data',
      }

      expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
      expect(provider).to receive(:influx_delete).with('/api/v2/dbrps/321?org=puppetlabs')

      provider.delete(context, should_hash[:name])
    end
  end
end
