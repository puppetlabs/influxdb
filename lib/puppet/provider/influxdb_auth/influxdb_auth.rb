# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbAuth::InfluxdbAuth < Puppet::Provider::Influxdb::Influxdb
  def get(_context)
    init_attrs
    init_auth
    get_org_info

    response = influx_get('/api/v2/authorizations', params: {})
    if response['authorizations']
      @self_hash = response['authorizations']

      response['authorizations'].reduce([]) do |memo, value|
        memo + [
          {
            # TODO: terrible idea?  There's isn't a "name" attribute for a token, so what is our namevar
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
      influxdb_host: @influxdb_host,
      orgID: id_from_name(@org_hash, should[:org]),
      permissions: should[:permissions],
      description: name,
      status: should[:status],
    }

    influx_post('/api/v2/authorizations', JSON.dump(body))
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    # A token cannot be updated, so we delete and create a new one
    delete(context, name)
    create(context, name, should)
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    token_id = @self_hash.find { |auth| auth['description'] == name }.dig('id')
    influx_delete("/api/v2/authorizations/#{token_id}")
  end
end
