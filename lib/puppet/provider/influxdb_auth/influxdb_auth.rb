# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbAuth::InfluxdbAuth < Puppet::ResourceApi::SimpleProvider
  include PuppetX::Puppetlabs::PuppetlabsInfluxdb
  def initialize
    @canonicalized_resources = []
    super
  end

  def canonicalize(_context, resources)
    init_attrs(resources)
    resources
  end

  def get(_context)
    init_auth
    get_org_info

    response = influx_get('/api/v2/authorizations', params: {})
    if response['authorizations']
      @self_hash = response['authorizations']

      response['authorizations'].reduce([]) do |memo, value|
        memo + [
          {
            name: value['description'],
            ensure: 'present',
            permissions: value['permissions'],
            status: value['status'],
            user: value['user'],
            org: value['org'],
          },
        ]
      end
    else
      []
    end
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = {
      orgID: id_from_name(@org_hash, should[:org]),
      permissions: should[:permissions],
      description: name,
      status: should[:status],
      user: should[:user] ? should[:user] : 'admin'
    }

    influx_post('/api/v2/authorizations', JSON.dump(body))
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    self_token = @self_hash.find { |auth| auth['description'] == name }

    # If the status property is unchanged, then a different, immutable property has been changed.
    if self_token['status'] == should[:status]
      context.warning("Unable to update properties other than 'status'.  Please delete and recreate resource with the desired properties")
    else
      auth_id = self_token['id']
      body = {
        status: should[:status],
        description: name,
      }

      influx_patch("/api/v2/authorizations/#{auth_id}", JSON.dump(body))
    end
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    token_id = @self_hash.find { |auth| auth['description'] == name }.dig('id')
    influx_delete("/api/v2/authorizations/#{token_id}")
  end
end
