# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for managing InfluxDB labels using the Resource API.
class Puppet::Provider::InfluxdbLabel::InfluxdbLabel < Puppet::ResourceApi::SimpleProvider
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
    get_label_info

    response = influx_get('/api/v2/labels', params: {})
    if response['labels']
      response['labels'].map do |label|
        {
          name: label['name'],
          ensure: 'present',
          org: name_from_id(@org_hash, label['orgID']),
          properties: label['properties'],
        }
      end
    else
      []
    end
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = {
      name: name,
      orgID: id_from_name(@org_hash, should[:org]),
      properties: should[:properties],
    }

    influx_post('/api/v2/labels', JSON.dump(body))
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")

    label_id = id_from_name(@label_hash, name)
    body = {
      name: name,
      properties: should[:properties],
    }

    influx_patch("/api/v2/labels/#{label_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    label_id = id_from_name(@label_hash, name)
    influx_delete("/api/v2/labels/#{label_id}")
  end
end
