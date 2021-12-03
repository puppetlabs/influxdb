# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbUser::InfluxdbUser < Puppet::Provider::Influxdb::Influxdb
  @user_map

  def member_map()
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
      @user_map = response['users']
      org_members = member_map()

      response['users'].reduce([]) { |memo, value|
        name = value['name']
        id = value['id']

        user_orgs = org_members.map { |org|
          org['name'] if org['members'].map { |m| m['id'] }.include? id
        }

        memo + [
          {
            influxdb_host: @@influxdb_host,
            name: name,
            ensure: 'present',
            status: value['status'],
            orgs: user_orgs ? user_orgs : [],
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
          orgs: nil,
        }
      ]
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    body = { name: should[:name] }
    influx_post('/api/v2/users', JSON.dump(body))

    # Org membership is determined by /orgs, so we need to first create the user and then update it
    update(context, name, should)
  end

  def update(context, name, should)
    @user_map = influx_get('/api/v2/users', params: {})['users']
    context.notice("Updating '#{name}' with #{should.inspect}")

    # Submit a POST request to /orgs/<org>/members for each <org>
    should[:orgs].each { |org|
      org_id = org_id_from_name(org)
      body = { id: user_id_from_name(name) }
      influx_post("/api/v2/orgs/#{org_id}/members", body.to_json)
    }
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = user_id_from_name(name)
    influx_delete("/api/v2/users/#{id}")
  end

  def user_id_from_name(name)
    @user_map.select {|user| user['name'] == name}.map { |user| user['id'] }.first
  end
  def user_name_from_id(id)
    @user_map.select {|user| user['id'] == id}.map { |user| user['name'] }.first
  end

end
