# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::InfluxdbBucket')
require 'puppet/provider/influxdb_bucket/influxdb_bucket'
require_relative '../../../../../lib/puppet_x/puppetlabs/influxdb/influxdb'
include PuppetX::Puppetlabs::PuppetlabsInfluxdb

RSpec.describe Puppet::Provider::InfluxdbBucket::InfluxdbBucket do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      name: {
        type: 'String',
      },
      labels: {
        type: 'Optional[Array[String]]',
      },
      org: {
        type: 'String',
      },
      retention_rules: {
        type: 'Array',
      },
      members: {
        type: 'Optional[Array[String]]',
      },
      create_dbrp: {
        type: 'Boolean',
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

  let(:label_response) do
    [{
      'links' => {
        'self' => '/api/v2/labels'
      },
      'labels' => [
        {
          'id' => '1234',
          'orgID' => '123',
          'name' => 'puppetlabs/influxdb',
          'links' => {
            'self' => '/api/v2/labels/1234',
          },
        },
      ]
    }]
  end

  let(:user_response) do
    [{
      'links' => {
        'self' => '/api/v2/users'
      },
      'users' => [
        {
          'links' => {
            'self' => '/api/v2/users/123456'
          },
          'id' => '123456',
          'name' => 'admin',
          'status' => 'active'
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
    # You must create a bucket during initial setup, so there will always be one returned by the provider
    context 'with bucket resources' do
      # rubocop:disable RSpec/SubjectStub
      it 'processes resources' do
        allow(provider).to receive(:influx_get).with('/api/v2/orgs').and_return(org_response)
        allow(provider).to receive(:influx_get).with('/api/v2/buckets').and_return(bucket_response)
        allow(provider).to receive(:influx_get).with('/api/v2/labels').and_return(label_response)
        allow(provider).to receive(:influx_get).with('/api/v2/dbrps?orgID=123').and_return(dbrp_response)
        allow(provider).to receive(:influx_get).with('/api/v2/users').and_return(user_response)

        provider.instance_variable_set('@use_ssl', true)
        provider.instance_variable_set('@host', 'foo.bar.com')
        provider.instance_variable_set('@port', 8086)
        provider.instance_variable_set('@token_file', '/root/.influxdb_token')
        provider.instance_variable_set('@token', RSpec::Puppet::Sensitive.new('puppetlabs'))

        should_hash = [
          { name: 'puppet_data',
            ensure: 'present',
            use_ssl: true,
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            org: 'puppetlabs',
            retention_rules: [{ 'type' => 'expire', 'everySeconds' => 2_592_000, 'shardGroupDurationSeconds' => 604_800 }],
            members: [],
            labels: [],
            create_dbrp: true },
        ]

        expect(provider.get(context)).to eq should_hash
      end
    end

    # context 'with paginated api response' do
    #  it 'processes paginated responses' do
    #    response_1 = [{
    #      'links' => {
    #        'self' => '/api/v2/buckets?descending=false&limit=20&offset=0',
    #        'next' => '/api/v2/buckets?descending=false&limit=20&offset=20'
    #      },
    #      'buckets' => [
    #          {
    #            'id' => '1231',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '1',
    #            'links' => {
    #              'self' => '/api/v2/buckets/1',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1232',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '2',
    #            'links' => {
    #              'self' => '/api/v2/buckets/2',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1233',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '3',
    #            'links' => {
    #              'self' => '/api/v2/buckets/3',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1234',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '4',
    #            'links' => {
    #              'self' => '/api/v2/buckets/4',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1235',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '5',
    #            'links' => {
    #              'self' => '/api/v2/buckets/5',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1236',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '6',
    #            'links' => {
    #              'self' => '/api/v2/buckets/6',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1237',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '7',
    #            'links' => {
    #              'self' => '/api/v2/buckets/7',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1238',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '8',
    #            'links' => {
    #              'self' => '/api/v2/buckets/8',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '1239',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '9',
    #            'links' => {
    #              'self' => '/api/v2/buckets/9',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12310',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '10',
    #            'links' => {
    #              'self' => '/api/v2/buckets/10',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12311',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '11',
    #            'links' => {
    #              'self' => '/api/v2/buckets/11',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12312',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '12',
    #            'links' => {
    #              'self' => '/api/v2/buckets/12',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12313',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '13',
    #            'links' => {
    #              'self' => '/api/v2/buckets/13',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12314',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '14',
    #            'links' => {
    #              'self' => '/api/v2/buckets/14',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12315',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '15',
    #            'links' => {
    #              'self' => '/api/v2/buckets/15',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12316',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '16',
    #            'links' => {
    #              'self' => '/api/v2/buckets/16',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12317',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '17',
    #            'links' => {
    #              'self' => '/api/v2/buckets/17',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12318',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '18',
    #            'links' => {
    #              'self' => '/api/v2/buckets/18',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12319',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '19',
    #            'links' => {
    #              'self' => '/api/v2/buckets/19',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #          {
    #            'id' => '12320',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '20',
    #            'links' => {
    #              'self' => '/api/v2/buckets/20',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #      ]
    #    }]

    #    response_2 = [{
    #      'links' => {
    #        'self' => '/api/v2/buckets?descending=false&limit=20&offset=20',
    #        'prev' => '/api/v2/buckets?descending=false&limit=20&offset=0'
    #      },
    #      'buckets' => [
    #          {
    #            'id' => '12321',
    #            'orgID' => '123',
    #            'type' => 'user',
    #            'name' => '21',
    #            'links' => {
    #              'self' => '/api/v2/buckets/21',
    #            },
    #            'retentionRules' => [
    #              {
    #                'type' => 'expire',
    #                'everySeconds' => 2_592_000,
    #                'shardGroupDurationSeconds' => 604_800
    #              },
    #            ],
    #            'labels' => { 'links' => { 'self' => '/api/v2/labels' }, 'labels' => [] }
    #          },
    #      ]
    #    }]

    #    allow(provider).to receive(:influx_get).with('/api/v2/orgs').and_return(org_response)
    #    #allow(provider).to receive(:get_bucket_info)
    #    allow(provider).to receive(:influx_get).with('/api/v2/buckets').and_return(response_1)
    #    allow(provider).to receive(:influx_get).with('/api/v2/labels').and_return(label_response)
    #    allow(provider).to receive(:influx_get).with('/api/v2/dbrps?orgID=123').and_return(dbrp_response)
    #    allow(provider).to receive(:influx_get).with('/api/v2/users').and_return(user_response)

    #    provider.instance_variable_set('@use_ssl', true)
    #    provider.instance_variable_set('@host', 'foo.bar.com')
    #    provider.instance_variable_set('@port', 8086)
    #    provider.instance_variable_set('@token_file', '/root/.influxdb_token')
    #    provider.instance_variable_set('@token', RSpec::Puppet::Sensitive.new('puppetlabs'))

    #    expect(provider).to receive(:influx_get).with("/api/v2/buckets")
    #    expect(provider).to receive(:influx_get).with("/api/v2/buckets?descending=false&limit=20&offset=20")
    #    provider.get(context)
    #  end
    # end
  end

  describe '#create' do
    let(:should_hash) do
      {
        name: 'puppet_data',
        org: 'puppetlabs',
      }
    end

    it 'creates resources' do
      post_args = ['/api/v2/buckets', JSON.dump({ name: 'puppet_data', orgId: 123, retentionRules: nil })]

      provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
      provider.instance_variable_set('@bucket_hash', [{ 'name' => 'puppet_data', 'id' => 12_345 }])

      allow(provider).to receive(:influx_get).with('/api/v2/buckets').and_return(bucket_response)
      allow(provider).to receive(:influx_post).with(*post_args)

      expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")
      provider.create(context, should_hash[:name], should_hash)
    end
  end

  describe '#update' do
    context 'without users' do
      let(:should_hash) do
        {
          name: 'puppet_data',
          org: 'puppetlabs',
          members: ['Alice', 'Bob'],
          retention_rules: [{
            type: 'expire',
            everySeconds: 2_592_000,
            shardGroupDurationSeconds: 604_800
          }]
        }
      end

      it 'warns about missing users' do
        provider.instance_variable_set(
          '@bucket_hash',
          [
            {
              'name' => 'puppet_data',
              'id' => 12_345,
              'labels' => [{
                'links' => {
                  'self' => '/api/v2/labels'
                },
                'labels' => [],
                'members' => [{
                  'links' => {
                    'self' => '/api/v2/buckets/12345/members'
                  },
                'users' => []
                }]
              }]
            },
          ],
        )
        patch_args = ['/api/v2/buckets/12345', JSON.dump({ name: should_hash[:name], retentionRules: should_hash[:retention_rules] })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:warning).with('Could not find user Alice')
        expect(context).to receive(:warning).with('Could not find user Bob')
        expect(provider).to receive(:influx_patch).with(*patch_args)

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'with users' do
      let(:should_hash) do
        {
          name: 'puppet_data',
          org: 'puppetlabs',
          members: ['Alice', 'Bob'],
          retention_rules: [{
            type: 'expire',
            everySeconds: 2_592_000,
            shardGroupDurationSeconds: 604_800
          }]
        }
      end

      it 'adds users to the bucket' do
        provider.instance_variable_set(
          '@bucket_hash',
          [
            {
              'name' => 'puppet_data',
              'id' => 12_345,
              'labels' => [{
                'links' => {
                  'self' => '/api/v2/labels'
                },
                'labels' => []
              }],
              'members' => [{
                'links' => {
                  'self' => '/api/v2/buckets/12345/members'
                },
                'users' => []
              }]
            },
          ],
        )

        provider.instance_variable_set(
          '@user_map',
          [
            {
              'links' => {
                'self' => '/api/v2/users/321'
              },
              'id' => '321',
              'name' => 'Bob',
              'status' => 'active'
            },
            {
              'links' => {
                'self' => '/api/v2/users/4321'
              },
              'id' => '4321',
              'name' => 'Alice',
              'status' => 'active'
            },
          ],
        )

        patch_args = ['/api/v2/buckets/12345', JSON.dump({ name: should_hash[:name], retentionRules: should_hash[:retention_rules] })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).not_to receive(:warning)
        expect(provider).to receive(:influx_patch).with(*patch_args)
        expect(provider).to receive(:influx_post).with('/api/v2/buckets/12345/members', JSON.dump({ id: '4321' }))
        expect(provider).to receive(:influx_post).with('/api/v2/buckets/12345/members', JSON.dump({ id: '321' }))

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'without labels' do
      let(:should_hash) do
        {
          name: 'puppet_data',
          org: 'puppetlabs',
          labels: ['label_1', 'label_2']
        }
      end

      it 'warns about missing labels' do
        provider.instance_variable_set(
          '@bucket_hash',
          [
            {
              'name' => 'puppet_data',
              'id' => 12_345,
              'labels' => [{
                'links' => {
                  'self' => '/api/v2/labels'
                },
                'labels' => []
              }],
              'members' => [{
                'links' => {
                  'self' => '/api/v2/buckets/12345/members'
                },
                'users' => []
              }]
            },
          ],
        )

        patch_args = ['/api/v2/buckets/12345', JSON.dump({ name: should_hash[:name], retentionRules: should_hash[:retention_rules] })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:warning).with('Could not find label label_1')
        expect(context).to receive(:warning).with('Could not find label label_2')
        expect(provider).to receive(:influx_patch).with(*patch_args)

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'with labels' do
      let(:should_hash) do
        {
          name: 'puppet_data',
          org: 'puppetlabs',
          labels: ['label_1', 'label_2']
        }
      end

      it 'adds labels to the bucket' do
        provider.instance_variable_set(
          '@bucket_hash',
          [
            {
              'name' => 'puppet_data',
              'id' => 12_345,
              'labels' => [{
                'links' => {
                  'self' => '/api/v2/labels'
                },
                'labels' => []
              }],
              'members' => [{
                'links' => {
                  'self' => '/api/v2/buckets/12345/members'
                },
                'users' => []
              }]
            },
          ],
        )

        provider.instance_variable_set(
          '@label_hash',
          [
            {
              'id' => '321',
              'orgID' => '123',
              'name' => 'label_1'
            },
            {
              'id' => '3210',
              'orgID' => '123',
              'name' => 'label_2'
            },
          ],
        )

        patch_args = ['/api/v2/buckets/12345', JSON.dump({ name: should_hash[:name], retentionRules: should_hash[:retention_rules] })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).not_to receive(:warning)
        expect(provider).to receive(:influx_patch).with(*patch_args)
        expect(provider).to receive(:influx_post).with('/api/v2/buckets/12345/labels', JSON.dump({ labelID: '321' }))
        expect(provider).to receive(:influx_post).with('/api/v2/buckets/12345/labels', JSON.dump({ labelID: '3210' }))

        provider.update(context, should_hash[:name], should_hash)
      end
    end
  end

  describe '#delete' do
    it 'deletes resources' do
      provider.instance_variable_set(
        '@bucket_hash',
        [
          {
            'name' => 'puppet_data',
            'id' => 12_345,
            'labels' => {
              'links' => {
                'self' => '/api/v2/labels'
              },
              'labels' => []
            },
            'members' => {
              'links' => {
                'self' => '/api/v2/buckets/12345/members'
              },
              'users' => []
            }
          },
        ],
      )

      should_hash = {
        ensure: 'absent',
        name: 'puppet_data',
      }

      expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
      expect(provider).to receive(:influx_delete).with('/api/v2/buckets/12345')

      provider.delete(context, should_hash[:name])
    end
  end
end
