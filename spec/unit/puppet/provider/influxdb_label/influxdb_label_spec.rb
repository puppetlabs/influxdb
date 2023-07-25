# frozen_string_literal: true

require 'spec_helper'
require 'json'

ensure_module_defined('Puppet::Provider::InfluxdbLabel')
require 'puppet/provider/influxdb_label/influxdb_label'
require_relative '../../../../../lib/puppet_x/puppetlabs/influxdb/influxdb'
include PuppetX::Puppetlabs::PuppetlabsInfluxdb

RSpec.describe Puppet::Provider::InfluxdbLabel::InfluxdbLabel do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:attrs) do
    {
      name: {
        type: 'String',
      },
      org: {
        type: 'String',
      },
      properties: {
        type: 'Optional[Hash]',
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

  describe '#get' do
    # rubocop:disable RSpec/SubjectStub
    it 'processes resources' do
      provider.instance_variable_set('@use_ssl', true)
      provider.instance_variable_set('@host', 'foo.bar.com')
      provider.instance_variable_set('@port', 8086)
      provider.instance_variable_set('@token_file', '/root/.influxdb_token')
      provider.instance_variable_set('@token', RSpec::Puppet::Sensitive.new('puppetlabs'))

      allow(provider).to receive(:influx_get).with('/api/v2/orgs').and_return(org_response)
      allow(provider).to receive(:influx_get).with('/api/v2/labels').and_return(label_response)

      should_hash = [
        {
          name: 'puppetlabs/influxdb',
          ensure: 'present',
          use_ssl: true,
          host: 'foo.bar.com',
          port: 8086,
          token: RSpec::Puppet::Sensitive.new('puppetlabs'),
          token_file: '/root/.influxdb_token',
          org: 'puppetlabs',
          properties: nil,
        },
      ]

      expect(provider.get(context)).to eq should_hash
    end

    context 'when using the system store' do
      it 'configures and uses the ssl context' do
        resources = [
          {
            name: 'puppetlabs/influxdb',
            ensure: 'present',
            use_ssl: true,
            use_system_store: true,
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            org: 'puppetlabs',
            properties: nil,
          },
        ]

        # canonicalize will set up the ssl_context and add it to the @client_options hash
        provider.canonicalize(context, resources)
        expect(provider.instance_variable_get('@client_options').key?(:ssl_context)).to eq true
      end

      it 'checks for a valid CA bundle' do
        resources = [
          {
            name: 'puppetlabs/influxdb',
            ensure: 'present',
            use_ssl: true,
            use_system_store: true,
            ca_bundle: '/not/a/file',
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            org: 'puppetlabs',
            properties: nil,
          },
        ]

        provider.canonicalize(context, resources)
        expect(instance_variable_get('@logs').any? { |log| log.message == 'No CA bundle found at /not/a/file' }).to eq true
      end
    end

    context 'when not using the system store' do
      it 'does not configure and uses the ssl context' do
        resources = [
          {
            name: 'puppetlabs/influxdb',
            ensure: 'present',
            use_ssl: true,
            use_system_store: false,
            ca_bundle: '/not/a/file',
            host: 'foo.bar.com',
            port: 8086,
            token: RSpec::Puppet::Sensitive.new('puppetlabs'),
            token_file: '/root/.influxdb_token',
            org: 'puppetlabs',
            properties: nil,
          },
        ]

        provider.canonicalize(context, resources)
        expect(provider.instance_variable_get('@client_options').key?(:ssl_context)).to eq false
      end
    end
  end

  describe '#create' do
    let(:should_hash) do
      {
        name: 'puppetlabs/influxdb',
        org: 'puppetlabs',
        properties: {
          description: 'A Puppet label'
        }
      }
    end

    it 'creates resources' do
      post_args = [
        '/api/v2/labels',
        JSON.dump(
          { name: 'puppetlabs/influxdb', orgID: 123, properties: { description: 'A Puppet label' } },
        ),
      ]
      provider.instance_variable_set('@org_hash', [{ 'name' => 'puppetlabs', 'id' => 123 }])

      expect(provider).to receive(:influx_post).with(*post_args)
      expect(context).to receive(:debug).with("Creating '#{should_hash[:name]}' with #{should_hash.inspect}")

      provider.create(context, should_hash[:name], should_hash)
    end
  end

  describe '#update' do
    let(:should_hash) do
      {
        name: 'puppetlabs/influxdb',
        org: 'puppetlabs',
        properties: {
          description: 'A different description'
        }
      }
    end

    it 'updates resources' do
      provider.instance_variable_set(
        '@label_hash',
        [{ 'id' => '321', 'orgID' => '123', 'name' => 'puppetlabs/influxdb' }],
      )

      patch_args = ['/api/v2/labels/321', JSON.dump({ name: should_hash[:name], properties: { description: 'A different description' } })]

      expect(context).to receive(:debug).with("Updating '#{should_hash[:name]}' with #{should_hash.inspect}")
      expect(provider).to receive(:influx_patch).with(*patch_args)

      provider.update(context, should_hash[:name], should_hash)
    end
  end

  describe '#delete' do
    it 'deletes resources' do
      provider.instance_variable_set(
        '@label_hash',
        [{ 'id' => '321', 'orgID' => '123', 'name' => 'puppetlabs/influxdb' }],
      )

      should_hash = {
        ensure: 'absent',
        name: 'puppetlabs/influxdb',
      }

      expect(context).to receive(:debug).with("Deleting '#{should_hash[:name]}'")
      expect(provider).to receive(:influx_delete).with('/api/v2/labels/321')

      provider.delete(context, should_hash[:name])
    end
  end
end
