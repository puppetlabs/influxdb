# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbBucket::InfluxdbBucket < Puppet::Provider::Influxdb::Influxdb
  attr_accessor :bucket_hash
  def initialize()
    @bucket_hash = update_bucket_hash()
  end

  def update_bucket_hash()
    response = influx_get('/api/v2/buckets', params: {})
    if response['buckets']
      response['buckets'].select{ |bucket| bucket['type'] == 'user'}.map { |bucket|
        process_links(bucket, bucket['links'])
        bucket
      }
    else
      []
    end
  end

  def bucket_id_from_name(name)
    @bucket_hash.select {|bucket| bucket['name'] == name}.map { |bucket| bucket['id'] }.first
  end
  def bucket_name_from_id(id)
    @bucket_hash.select {|bucket| bucket['id'] == id}.map { |bucket| bucket['name'] }.first
  end

  def get(context)
    response = influx_get('/api/v2/buckets', params: {})
    if response['buckets']
      response['buckets'].select{ |bucket| bucket['type'] == 'user'}.reduce([]) { |memo, value|
        memo + [
          {
            influxdb_host: @@influxdb_host,
            name: value['name'],
            ensure: 'present',
            org: org_name_from_id(value['orgID']),
            retention_rules: value['retentionRules'],
            labels: value['labels'],
          }
        ]
      }
    else
      [
        {
          influxdb_host: nil,
          name: nil,
          ensure: nil,
          org: nil,
          retention_rules: nil,
          labels: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = {
      name: should[:name],
      labels: should[:labels],
      orgId: org_id_from_name(name),
      retentionRules: should[:retention_rules],
    }
    response = influx_post('/api/v2/buckets', JSON.dump(body))
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    bucket_id = bucket_id_from_name(name)
    body = {
      name: should[:name],
      retentionRules: should[:retention_rules],
    }
    influx_patch("/api/v2/buckets/#{bucket_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = bucket_id_from_name(name)
    influx_delete("/api/v2/buckets/#{id}")
  end
end
