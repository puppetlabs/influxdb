# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbOrg::InfluxdbOrg < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    response = influx_get('/api/v2/orgs', params: {})
    if response['orgs']
      response['orgs'].reduce([]) { |memo, value|
        memo + [
          {
            influxdb_host: @@influxdb_host,
            org: value['name'],
            ensure: 'present',
            desc: value['description']
          }
        ]
      }
    else
      [
        {
          influxdb_host: @@influxdb_host,
          org: nil,
          ensure: 'absent',
          desc: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    body = {name: should[:org], description: should[:desc]}
    influx_post('/api/v2/orgs', body.to_s)
  end

  #TODO: utility method to create an instance variable with org information.  /orgs should make this easy, as it has links to
  # all the apis needed to get this info
  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    body = {name: should[:org], description: should[:desc]}
    #influx_patch("orgs/#{should['id']}", body.to_json)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

end
