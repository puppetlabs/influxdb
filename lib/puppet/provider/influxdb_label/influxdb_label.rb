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
  rescue StandardError => e
    context.err("Error canonicalizing resources: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def get(_context)
    init_auth if @auth.empty?
    get_org_info if @org_hash.empty?
    get_label_info if @label_hash.empty?

    response = influx_get('/api/v2/labels')
    ret = []

    response.each do |r|
      next unless r['labels']
      r['labels'].each do |label|
        ret << {
          name: label['name'],
          use_ssl: @use_ssl,
          host: @host,
          port: @port,
          token: @token,
          token_file: @token_file,
          ensure: 'present',
          org: name_from_id(@org_hash, label['orgID']),
          properties: label['properties'],
        }
      end
    end

    ret
  rescue StandardError => e
    context.err("Error getting label state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = {
      name: name,
      orgID: id_from_name(@org_hash, should[:org]),
      properties: should[:properties],
    }

    influx_post('/api/v2/labels', JSON.dump(body))
  rescue StandardError => e
    context.err("Error setting label state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")

    label_id = id_from_name(@label_hash, name)
    body = {
      name: name,
      properties: should[:properties],
    }

    influx_patch("/api/v2/labels/#{label_id}", JSON.dump(body))
  rescue StandardError => e
    context.err("Error updating label state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    label_id = id_from_name(@label_hash, name)
    influx_delete("/api/v2/labels/#{label_id}")
  end
rescue StandardError => e
  context.err("Error deleting label state: #{e.message}")
  context.err(e.backtrace)
  nil
end
