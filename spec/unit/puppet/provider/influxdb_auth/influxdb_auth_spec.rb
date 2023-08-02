# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::InfluxdbAuth')
require 'puppet/provider/influxdb_auth/influxdb_auth'
require_relative '../../../../../lib/puppet_x/puppetlabs/influxdb/influxdb'
include PuppetX::Puppetlabs::PuppetlabsInfluxdb

RSpec.describe Puppet::Provider::InfluxdbAuth::InfluxdbAuth do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      status: {
        type: 'Enum[active, inactive]',
      },
      org: {
        type: 'String',
      },
      user: {
        type: 'Optional[String]',
      },
      permissions: {
        type: 'Array[Hash]',
      }
    }
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

  let(:auth_response) do
    [{
      'links' => {
        'self' => '/api/v2/authorizations'
      },
      'authorizations' => [
        {
          'id' => '123',
          'user' => 'admin',
          'token' => '321',
          'status' => 'active',
          'description' => 'token_1',
          'orgID' => '123',
          'org' => 'puppetlabs',
          'permissions' => [
            {
              'action' => 'read',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
          ],
          'links' => {
            'self' => '/api/v2/authorizations/123',
          }
        },
      ]
    }]
  end

  describe '#get' do
    # rubocop:disable RSpec/SubjectStub
    it 'processes resources' do
      allow(provider).to receive(:influx_get).with('/api/v2/orgs').and_return(org_response)
      provider.instance_variable_set('@use_ssl', true)
      provider.instance_variable_set('@host', 'foo.bar.com')
      provider.instance_variable_set('@port', 8086)
      provider.instance_variable_set('@token_file', '/root/.influxdb_token')
      provider.instance_variable_set('@token', RSpec::Puppet::Sensitive.new('puppetlabs'))

      should_hash = [
        {
          ensure: 'present',
          use_ssl: true,
          host: 'foo.bar.com',
          port: 8086,
          token: RSpec::Puppet::Sensitive.new('puppetlabs'),
          token_file: '/root/.influxdb_token',
          user: 'admin',
          name: 'token_1',
          status: 'active',
          org: 'puppetlabs',
          permissions: [
            {
              'action' => 'read',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
          ]
        },
      ]

      allow(provider).to receive(:influx_get).with('/api/v2/authorizations').and_return(auth_response)
      expect(provider.get(context)).to eq should_hash
    end

    context 'when using the system store' do
      it 'configures and uses the ssl context' do
        resources = [
          {
            ensure: 'present',
            use_ssl: true,
            use_system_store: true,
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            user: 'admin',
            name: 'token_1',
            status: 'active',
            org: 'puppetlabs',
            permissions: [
              {
                'action' => 'read',
                'resource' => {
                  'type' => 'telegrafs'
                }
              },
            ]
          },
        ]

        # canonicalize will set up the include_system_store and add it to the @client_options hash
        provider.canonicalize(context, resources)
        expect(provider.instance_variable_get('@client_options').key?(:include_system_store)).to eq true
      end
    end

    context 'when not using the system store' do
      it 'does not configure and uses the ssl context' do
        resources = [
          {
            ensure: 'present',
            use_ssl: true,
            use_system_store: false,
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            user: 'admin',
            name: 'token_1',
            status: 'active',
            org: 'puppetlabs',
            permissions: [
              {
                'action' => 'read',
                'resource' => {
                  'type' => 'telegrafs'
                }
              },
            ]
          },
        ]

        provider.canonicalize(context, resources)
        expect(provider.instance_variable_get('@client_options').key?(:include_system_store)).to eq false
      end
    end
  end

  describe '#create' do
    let(:should_hash) do
      {
        ensure: 'present',
        user: 'admin',
        name: 'token_1',
        status: 'active',
        org: 'puppetlabs',
        permissions: [
          {
            'action' => 'read',
            'resource' => {
              'type' => 'telegrafs'
            }
          },
        ]
      }
    end

    it 'creates resources' do
      post_args = {
        orgID: 123,
        permissions: [
          {
            'action' => 'read',
            'resource' => {
              'type' => 'telegrafs'
            }
          },
        ],
        description: 'token_1',
        status: 'active',
        userID: 123,
      }

      provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
      provider.instance_variable_set('@user_map', [{ 'name' => 'admin', 'id' => 123 }])

      expect(provider).to receive(:influx_post).with('/api/v2/authorizations', JSON.dump(post_args))
      expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")

      provider.create(context, should_hash[:name], should_hash)
    end
  end

  describe '#update' do
    context 'when updating status' do
      it 'updates resources' do
        should_hash = {
          ensure: 'present',
          user: 'admin',
          name: 'token_1',
          status: 'inactive',
          org: 'puppetlabs',
          permissions: [
            {
              'action' => 'read',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
          ]
        }

        provider.instance_variable_set(
          '@self_hash',
          [
            {
              'id' => '123',
              'token' => 'foo',
              'status' => 'active',
              'description' => 'token_1',
              'orgID' => '123',
              'org' => 'puppetlabs',
              'userID' => '123',
              'user' => 'admin',
              'permissions' => [
                {
                  'action' => 'read',
                  'resource' => {
                    'type' => 'telegrafs'
                  }
                },
              ],
              'links' => {
                'self' => '/api/v2/authorizations/123',
              },
            },
          ],
        )

        patch_args = ['/api/v2/authorizations/123', JSON.dump({ status: 'inactive', description: 'token_1' })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).not_to receive(:warning)
        expect(provider).to receive(:influx_patch).with(*patch_args)

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'when updating immutable properties' do
      it 'produces a warning' do
        should_hash = {
          ensure: 'present',
          user: 'admin',
          name: 'token_1',
          status: 'active',
          org: 'puppetlabs',
          permissions: [
            {
              'action' => 'read',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
            {
              'action' => 'write',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
          ]
        }

        provider.instance_variable_set(
          '@self_hash',
          [
            {
              'id' => '123',
              'token' => 'foo',
              'status' => 'active',
              'description' => 'token_1',
              'orgID' => '123',
              'org' => 'puppetlabs',
              'userID' => '123',
              'user' => 'admin',
              'permissions' => [
                {
                  'action' => 'read',
                  'resource' => {
                    'type' => 'telegrafs'
                  }
                },
              ],
              'links' => {
                'self' => '/api/v2/authorizations/123',
              },
            },
          ],
        )

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:warning).with(
          "Unable to update properties other than 'status'.  Please delete and recreate resource with the desired properties",
        )

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'when force updating immutable properties' do
      it 'updates resources' do
        should_hash = {
          ensure: 'present',
          user: 'admin',
          name: 'token_1',
          status: 'active',
          org: 'puppetlabs',
          force: true,
          permissions: [
            {
              'action' => 'read',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
            {
              'action' => 'write',
              'resource' => {
                'type' => 'telegrafs'
              }
            },
          ]
        }

        provider.instance_variable_set(
          '@self_hash',
          [
            {
              'id' => '123',
              'token' => 'foo',
              'status' => 'active',
              'description' => 'token_1',
              'orgID' => '123',
              'org' => 'puppetlabs',
              'userID' => '123',
              'user' => 'admin',
              'permissions' => [
                {
                  'action' => 'read',
                  'resource' => {
                    'type' => 'telegrafs'
                  }
                },
              ],
              'links' => {
                'self' => '/api/v2/authorizations/123',
              },
            },
          ],
        )

        post_data = JSON.dump(
          {
            'orgID': 123,
            'permissions': [
              {
                'action': 'read',
                'resource': {
                  'type': 'telegrafs'
                }
              },
              {
                'action': 'write',
                'resource': {
                  'type': 'telegrafs'
                }
              },
            ],
            'description': 'token_1',
            'status': 'active',
            'userID': 123
          },
        )

        provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
        provider.instance_variable_set('@user_map', [{ 'name' => 'admin', 'id' => 123 }])

        post_args = ['/api/v2/authorizations', post_data]

        expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
        expect(provider).to receive(:influx_delete).with('/api/v2/authorizations/123')
        expect(provider).to receive(:influx_post).with(*post_args)

        provider.update(context, should_hash[:name], should_hash)
      end
    end
  end

  describe '#delete' do
    it 'deletes resources' do
      provider.instance_variable_set(
        '@self_hash',
        [
          {
            'id' => '123',
            'token' => 'foo',
            'status' => 'active',
            'description' => 'token_1',
            'orgID' => '123',
            'org' => 'puppetlabs',
            'userID' => '123',
            'user' => 'admin',
            'permissions' => [
              {
                'action' => 'read',
                'resource' => {
                  'type' => 'telegrafs'
                }
              },
            ],
            'links' => {
              'self' => '/api/v2/authorizations/123',
            },
          },
        ],
      )

      should_hash = {
        ensure: 'absent',
        name: 'token_1',
        token_id: '123',
      }

      expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
      expect(provider).to receive(:influx_delete).with('/api/v2/authorizations/123')

      provider.delete(context, should_hash[:name])
    end
  end
end
