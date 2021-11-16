# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/http'
require 'json'
require 'pry'
require 'uri'

# Implementation for the influxdb type using the Resource API.
class Puppet::Provider::Influxdb::Influxdb < Puppet::ResourceApi::SimpleProvider
  #TODO: is this a terrible idea
  @@client ||= Puppet.runtime[:http]

  def get(context)
    #TODO: This is currently duplicated in the influxdb_setup provider.  Not sure how to avoid it since we may not be managing the influxdb instance and thus not using the influxdb_setup type.
    response = influx_get('setup')
    # A response of allowed: true means initial setup has not been performed
    [
      {
        influxdb_host: 'localhost',
        ensure: response['allowed'] == true ? 'absent' : 'present',
      },
    ]
  end

  # This base provider doesn't have any resources to manage at the moment.  Setup is done via the influxdb_setup type
  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

  #TODO: configurable url
  #TODO: error checking
  def influx_get(name)
    response = @@client.get(URI('http://localhost:8086' + "/api/v2/#{name}")).body
    JSON.parse(response)
  end

  def influx_put(name, body)
    response = @@client.post(URI('http://localhost:8086' + "/api/v2/#{name}"), body , headers: {'Content-Type' => 'application/json'}).body
    JSON.parse(response)
  end
end
