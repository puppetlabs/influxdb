# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

class Puppet::Provider::InfluxdbLabel::InfluxdbLabel < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    init_attrs()
    init_auth()

    get_org_info()
    get_label_info()

    response = influx_get('/api/v2/labels', params: {})
    if response['labels']
      response['labels'].map{ |label|
        {
          name: label['name'],
          ensure: 'present',
          org: name_from_id(@org_hash, label['orgID']),
          properties: label['properties'],
        }
      }
    else
      []
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = {
      name: name,
      orgID: id_from_name(@org_hash, should[:org]),
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
