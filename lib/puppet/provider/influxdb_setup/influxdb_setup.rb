# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbSetup::InfluxdbSetup < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    init_attrs()

    response = influx_get('/api/v2/setup', params: {})
    [
      {
        name: @influxdb_host,
        ensure: response['allowed'] == true ? 'absent' : 'present',
      },
    ]
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    body = {
      bucket: should[:bucket],
      org: should[:org],
      username: should[:username],
      password: should[:password].unwrap,
    }
    response = influx_post('/api/v2/setup', JSON.dump(body))
    File.write(should[:token_file], response['auth']['token'])
  end

  def update(context, name, should)
    context.warning("Unable to update setup resource")
  end

  def delete(context, name)
    context.warning("Unable to delete setup resource")
  end
end
