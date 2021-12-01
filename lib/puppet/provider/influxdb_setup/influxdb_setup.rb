# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbSetup::InfluxdbSetup < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    response = influx_get('/api/v2/setup', params: {})
    [
      {
        influxdb_host: @@influxdb_host,
        ensure: response['allowed'] == true ? 'absent' : 'present',
      },
    ]
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    response = influx_post('/api/v2/setup', '{"bucket": "puppet", "org": "puppetlabs", "username": "admin", "password": "puppetlabs"}')
    File.write("#{Dir.home}/.influxdb_token", response['auth']['token'])

  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
