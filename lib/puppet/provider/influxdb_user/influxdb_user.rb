# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
class Puppet::Provider::InfluxdbUser::InfluxdbUser < Puppet::ResourceApi::SimpleProvider
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
    get_user_info

    response = influx_get('/api/v2/users', params: {})
    if response['users']
      response['users'].reduce([]) do |memo, value|
        name = value['name']

        memo + [
          {
            name: name,
            ensure: 'present',
            status: value['status'],
          },
        ]
      end
    else
      [
        {
          name: nil,
          ensure: 'absent',
          status: nil,
        },
      ]
    end
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = { name: should[:name] }
    response = influx_post('/api/v2/users', JSON.dump(body))
    return unless should[:password] && response['id']

    body = { password: should[:password].unwrap }
    influx_post("/api/v2/users/#{response['id']}/password", JSON.dump(body))
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    user_id = id_from_name(@user_map, name)
    body = {
      name: name,
      status: should[:status],
    }
    influx_patch("/api/v2/users/#{user_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")
    id = id_from_name(@user_map, name)
    influx_delete("/api/v2/users/#{id}")
  end
end
