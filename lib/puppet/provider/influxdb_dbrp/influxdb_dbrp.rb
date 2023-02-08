# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbDbrp::InfluxdbDbrp < Puppet::ResourceApi::SimpleProvider
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
    get_bucket_info if @bucket_hash.empty?
    get_dbrp_info if @dbrp_hash.empty?

    @dbrp_hash.reduce([]) do |memo, value|
      memo + [
        {
          ensure: 'present',
          use_ssl: @use_ssl,
          host: @host,
          port: @port,
          token: @token,
          token_file: @token_file,
          name: value['database'],
          org: name_from_id(@org_hash, value['orgID']),
          bucket: name_from_id(@bucket_hash, value['bucketID']),
          is_default: value['default'],
          rp: value['retention_policy'],
        },
      ]
    end
  rescue StandardError => e
    context.err("Error getting dbrp state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = {
      bucketID: id_from_name(@bucket_hash, should[:bucket]),
      database: name,
      org: should[:org],
      retention_policy: should[:rp],
      default: should[:is_default],
    }
    influx_post("/api/v2/dbrps?org=#{should[:org]}", JSON.dump(body))
  rescue StandardError => e
    context.err("Error creating dbrp state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")

    dbrp_id = id_from_name(@dbrp_hash, name)
    body = {
      default: should[:is_default],
      retention_policy: should[:rp],
    }

    influx_patch("/api/v2/dbrps/#{dbrp_id}?org=#{should[:org]}", JSON.dump(body))
  rescue StandardError => e
    context.err("Error updating dbrp state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    self_entry = @dbrp_hash.find { |dbrp| dbrp['database'] == name }
    id = self_entry['id']
    org = name_from_id(@org_hash, self_entry['orgID'].to_i)

    influx_delete("/api/v2/dbrps/#{id}?org=#{org}")
  end
rescue StandardError => e
  context.err("Error deleting dbrp state: #{e.message}")
  context.err(e.backtrace)
  nil
end
