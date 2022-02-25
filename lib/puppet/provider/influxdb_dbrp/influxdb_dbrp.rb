# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbDbrp::InfluxdbDbrp < Puppet::Provider::Influxdb::Influxdb
  def get(_context)
    init_attrs
    init_auth

    get_org_info
    get_bucket_info
    get_dbrp_info

    @dbrp_hash.map { |dbrp| dbrp['content'] }.flatten.reduce([]) do |memo, value|
      memo + [
        {
          ensure: 'present',
          name: value['database'],
          org: name_from_id(@org_hash, value['orgID']),
          bucket: name_from_id(@bucket_hash, value['bucketID']),
          is_default: value['default'],
          rp: value['retention_policy'],
        },
      ]
    end
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
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    # TODO
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    self_entry = @dbrp_hash.map { |dbrp| dbrp['content'] }.flatten.find { |dbrp| dbrp['database'] == name }
    id = self_entry['id']
    org = name_from_id(@org_hash, self_entry['orgID'])

    influx_delete("/api/v2/dbrps/#{id}?org=#{org}")
  end
end
