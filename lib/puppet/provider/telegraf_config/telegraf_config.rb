# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'
require 'pp'
require 'toml-rb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::TelegrafConfig::TelegrafConfig < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    response = influx_get('/api/v2/telegrafs', params: {})
    if response['configurations']
      response['configurations'].reduce([]) { |memo, value|
        memo + [
          {
            name: value['name'],
            influxdb_host: @@influxdb_host,
            org: name_from_id(@@org_hash, value['orgID']),
            ensure: 'present',
            description: value['description'],
            config: TomlRB.parse(value['config']),
            metadata: value['metadata'],
          }
        ]
      }
    else
      []
    end
  end

  def create(context, name, should)
    context.info("Creating '#{name}' with #{should.inspect}")

    #FIXME
    if should[:config] and should[:source]
      raise Puppet::DevError, "Recieved mutually exclusive parameters: 'config' and 'source'."
    end

    body = {
      name: should[:name],
      description: should[:description],
      config: TomlRB.dump(should[:config]),
      metadata: should[:metadata],
      orgID: id_from_name(@@org_hash, should[:org])
    }
    response = influx_post('/api/v2/telegrafs', JSON.dump(body))
  end

  def update(context, name, should)
    context.info("Updating '#{name}' with #{should.inspect}")
    telegraf_id = id_from_name(@@telegraf_hash, should[:name])
    body = {
      name: should[:name],
      description: should[:description],
      config: TomlRB.dump(should[:config]),
      metadata: should[:metadata],
      orgID: id_from_name(@@org_hash, should[:org])
    }
    influx_put("/api/v2/telegrafs/#{telegraf_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.info("Deleting '#{name}'")
  end

end
