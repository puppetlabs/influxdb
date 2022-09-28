# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::InfluxdbOrg')
require 'puppet/provider/influxdb_org/influxdb_org'
require_relative '../../../../../lib/puppet_x/puppetlabs/influxdb/influxdb'
include PuppetX::Puppetlabs::PuppetlabsInfluxdb

RSpec.describe Puppet::Provider::InfluxdbOrg::InfluxdbOrg do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      name: {
        type: 'String',
      },
      members: {
        type: 'Optional[Array[String]]',
      },
      description: {
        type: 'Optional[String]',
      }
    }
  end

  let(:org_response) do
    {
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
    }
  end

  let(:user_response) do
    {
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
    }
  end

  describe '#get' do
    # rubocop:disable RSpec/SubjectStub
    it 'processes resources' do
      provider.instance_variable_set('@use_ssl', true)
      allow(provider).to receive(:influx_get).with('/api/v2/orgs', params: {}).and_return(org_response)
      allow(provider).to receive(:influx_get).with('/api/v2/users', params: {}).and_return(user_response)

      should_hash = [
        {
          name: 'puppetlabs',
          ensure: 'present',
          use_ssl: true,
          description: nil,
          members: [],
        },
      ]

      expect(provider.get(context)).to eq should_hash
    end
  end

  describe '#create' do
    let(:should_hash) do
      {
        name: 'puppetlabs',
        description: nil,
      }
    end

    it 'creates resources' do
      post_args = ['/api/v2/orgs', JSON.dump(should_hash)]

      expect(provider).to receive(:influx_post).with(*post_args)
      expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")

      provider.create(context, should_hash[:name], should_hash)
    end
  end

  describe '#update' do
    context 'with users' do
      let(:should_hash) do
        {
          name: 'puppetlabs',
          description: 'A new description',
          members: ['Alice', 'Bob']
        }
      end

      it 'adds users to the org' do
        provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
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

        patch_args = ['/api/v2/orgs/123', JSON.dump(description: 'A new description')]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).not_to receive(:warning)

        expect(provider).to receive(:influx_patch).with(*patch_args)
        expect(provider).to receive(:influx_post).with('/api/v2/orgs/123/members', JSON.dump({ name: 'Alice', id: '4321' }))
        expect(provider).to receive(:influx_post).with('/api/v2/orgs/123/members', JSON.dump({ name: 'Bob', id: '321' }))

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    context 'without users' do
      let(:should_hash) do
        {
          name: 'puppetlabs',
          members: ['Alice', 'Bob']
        }
      end

      it 'warns about missing users' do
        provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])
        patch_args = ['/api/v2/orgs/123', JSON.dump({ description: nil })]

        expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
        expect(context).to receive(:warning).with('Could not find user Alice')
        expect(context).to receive(:warning).with('Could not find user Bob')
        expect(provider).to receive(:influx_patch).with(*patch_args)

        provider.update(context, should_hash[:name], should_hash)
      end
    end

    describe '#delete' do
      it 'deletes resources' do
        provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])

        should_hash = {
          ensure: 'absent',
          name: 'puppetlabs',
        }

        expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
        expect(provider).to receive(:influx_delete).with('/api/v2/orgs/123')

        provider.delete(context, should_hash[:name])
      end
    end
  end
end
