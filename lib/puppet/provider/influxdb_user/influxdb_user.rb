# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbUser::InfluxdbUser < Puppet::Provider::Influxdb::Influxdb
  # Users belonging to an organization, per /orgs
  attr_accessor :org_user_map

  def initialize()
    @org_user_map = update_org_user_map
  end

  def update_org_user_map()
    @@org_hash.map { |org|
      members = org.dig('members', 'users')
      {
        'name' => org['name'],
        'members' => members ? members.map { |m| { 'name' => m['name'], 'id' => m['id']} } : nil
      }
    }
  end

  def get(context)
    response = influx_get('/api/v2/users', params: {})
    if response['users']
      response['users'].reduce([]) { |memo, value|
        name = value['name']
        id = value['id']

        memo + [
          {
            influxdb_host: @@influxdb_host,
            name: name,
            ensure: 'present',
            status: value['status'],
          }
        ]
      }
    else
      [
        {
          influxdb_host: @@influxdb_host,
          name: nil,
          ensure: 'absent',
          status: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = { name: should[:name] }
    response = influx_post('/api/v2/users', JSON.dump(body))
    puts 'create body'
    puts JSON.pretty_generate(response)
    if should[:password] and response['id']
      body = { password: should[:password].unwrap }
      influx_post("/api/v2/users/#{response['id']}/password", JSON.dump(body))
    end


    # Org membership is determined by /orgs, so we need to first create the user and then update it
    #TODO: only allow influxdb_org type to set membership?
    #update(context, name, should)
  end

  def update(context, name, should)
    #@@user_map = update_user_info
    context.notice("Updating '#{name}' with #{should.inspect}")
    user_id = id_from_name(@@user_map, name)
    body = {
      name: name,
      status: should[:status],
    }
    # Submit a POST request to /orgs/<org>/members for each <org>
    #should[:orgs].each { |org|
    #  org_id = id_from_name(@@org_hash, org)
    #  body = { id: id_from_name(@@user_map, name) }
    #  influx_post("/api/v2/orgs/#{org_id}/members", body.to_json)
    #}
    influx_patch("/api/v2/users/#{user_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = id_from_name(@@user_map, name)
    influx_delete("/api/v2/users/#{id}")
  end

end
