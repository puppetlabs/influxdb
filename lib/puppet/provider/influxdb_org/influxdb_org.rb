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
      org_members = @@org_hash.find{ |org| org['name'] == value['name']}.dig('members', 'users')
        memo + [
          {
            ensure: 'present',
            influxdb_host: @@influxdb_host,
            org: value['name'],
            members: org_members ? org_members.map {|member| member['name']} : [],
            description: value['description']
          }
        ]
      }
    else
      [
        {
          influxdb_host: @@influxdb_host,
          org: nil,
          ensure: 'absent',
          description: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    body = {
      name: should[:org],
      description: should[:description],
    }
    influx_post('/api/v2/orgs', body.to_s)
  end

  #TODO: utility method to create an instance variable with org information.  /orgs should make this easy, as it has links to
  # all the apis needed to get this info
  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    org_id = id_from_name(@@org_hash, name)
    org_members = @@org_hash.find{ |org| org['name'] == name}.dig('members', 'users')

    to_remove = org_members.map{ |user| user['name']} - should[:members]
    to_add = should[:members] - org_members.map{ |user| user['name']}

    to_remove.each { |user|
      next if user == 'admin'
      user_id = id_from_name(@@user_map, user)
      url = "/api/v2/orgs/#{org_id}/members/#{user_id}"
      influx_delete(url)
    }
    to_add.each { |user|
      user_id = id_from_name(@@user_map, user)
      body = { name: user, id: user_id }
      url = "/api/v2/orgs/#{org_id}/members"
      influx_post(url, JSON.dump(body))
    }

    body = { description: should[:description], }
    influx_patch("/api/v2/orgs/#{org_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

end
