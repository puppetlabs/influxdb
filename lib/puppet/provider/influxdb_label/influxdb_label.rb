# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

class Puppet::Provider::InfluxdbLabel::InfluxdbLabel < Puppet::Provider::Influxdb::Influxdb
  attr_accessor :label_hash
  def initialize()
    @label_hash = update_label_hash()
  end

  def update_label_hash()
    response = influx_get('/api/v2/labels', params: {})
    # No 'links' entries for individual labels as of now
    response['labels'] ? response['labels']: []
  end

  def get(context)
    response = influx_get('/api/v2/labels', params: {})
    if response['labels']
      puts JSON.pretty_generate(response['labels'])
      response['labels'].map{ |label|
        {
          influxdb_host: @@influxdb_host,
          name: label['name'],
          ensure: 'present',
          org: name_from_id(@@org_hash, label['orgID']),
          properties: label['properties'],
        }
      }
    else
      [
        {
          influxdb_host: @@influxdb_host,
          name: nil,
          ensure: 'absent',
          org: nil,
          properties: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = {
      name: name,
      orgID: id_from_name(@@org_hash, should[:org]),
      properties: should[:properties],
    }

    influx_post('/api/v2/labels', JSON.dump(body))
  end

  def update(context, name, should)
    label_id = id_from_name(@label_hash, name)
    body = {
      name: name,
      properties: should[:properties],
    }

    influx_patch("/api/v2/labels/#{label_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    label_id = id_from_name(@label_hash, name)
    influx_delete("/api/v2/labels/#{label_id}")
  end
end
