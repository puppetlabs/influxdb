# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbBucket::InfluxdbBucket < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    init_attrs()
    init_auth()
    init_data()

    #TODO: refactor this one to be like other hashes
    response = influx_get('/api/v2/buckets', params: {})
    if response['buckets']
      response['buckets'].select{ |bucket| bucket['type'] == 'user'}.reduce([]) { |memo, value|
        links_hash = @bucket_hash.find{ |b| b['name'] == value['name']}
        bucket_members = links_hash.dig('members', 'users')
        bucket_labels = links_hash.dig('labels', 'labels')

        memo + [
          {
            name: value['name'],
            ensure: 'present',
            org: name_from_id(@org_hash, value['orgID']),
            retention_rules: value['retentionRules'],
            members: bucket_members ? bucket_members.map {|member| member['name']} : [],
            labels: bucket_labels ? bucket_labels.map {|label| label['name']} : [],
          }
        ]
      }
    else
      []
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = {
      name: should[:name],
      orgId: id_from_name(@org_hash, should[:org]),
      retentionRules: should[:retention_rules],
    }
    response = influx_post('/api/v2/buckets', JSON.dump(body))

    #update(context, name, should) if should[:labels]
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    bucket_id = bucket_id_from_name(name)

    #TODO: move the "user map" code to the base class so this code is less ugly
    bucket_members = @bucket_hash.find{ |bucket| bucket['name'] == name}.dig('members', 'users')
    bucket_labels = @bucket_hash.find{ |bucket| bucket['name'] == name}.dig('labels', 'labels')
    bucket_users = bucket_members ? bucket_members.map{ |user| {'name' => user['name'], 'id' => user['id'] } } : []

    users_to_remove = bucket_users.map{ |user| user['name']} - should[:members]
    users_to_add = should[:members] - bucket_users

    users_to_remove.each{ |user|
      user_id = bucket_users.select{ |u| u['name'] == user}.map{ |u| u['id'] }.first
      influx_delete("/api/v2/buckets/#{bucket_id}/members/#{user_id}")
    }
    users_to_add.each{ |user|
      body = { 'id' => id_from_name(@user_hash, user) }
      influx_post("/api/v2/buckets/#{bucket_id}/members", body.to_json)
    }

    labels_to_remove = bucket_labels.map{ |label| label['name']} - should[:labels]
    labels_to_add = should[:labels] - bucket_labels.map{ |label| label['name']}

    labels_to_remove.each{ |label|
      label_id = id_from_name(@label_hash, label)
      influx_delete("/api/v2/buckets/#{bucket_id}/labels/#{label_id}")
    }
    labels_to_add.each{ |label|
      label_id = id_from_name(@label_hash, label)
      body = { 'labelID' => label_id }
      influx_post("/api/v2/buckets/#{bucket_id}/labels", JSON.dump(body))
    }

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
