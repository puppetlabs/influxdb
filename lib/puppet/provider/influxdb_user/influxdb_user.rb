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
  rescue StandardError => e
    context.err("Error canonicalizing resources: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def get(_context)
    init_auth if @auth.empty?
    get_user_info if @user_map.empty?

    response = influx_get('/api/v2/users')
    ret = []
    response.each do |r|
      next unless r['users']

      r['users'].each do |value|
        ret << {
          name: value['name'],
          use_ssl: @use_ssl,
          host: @host,
          port: @port,
          token: @token,
          token_file: @token_file,
          ensure: 'present',
          status: value['status'],
        }
      end
    end

    ret
  rescue StandardError => e
    context.err("Error getting user state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = { name: should[:name] }
    response = influx_post('/api/v2/users', JSON.dump(body))
    return unless should[:password] && response['id']

    body = { password: should[:password].unwrap }
    influx_post("/api/v2/users/#{response['id']}/password", JSON.dump(body))
  rescue StandardError => e
    context.err("Error creating user state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    user_id = id_from_name(@user_map, name)
    body = {
      name: name,
      status: should[:status],
    }
    influx_patch("/api/v2/users/#{user_id}", JSON.dump(body))
  rescue StandardError => e
    context.err("Error updating user state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")
    id = id_from_name(@user_map, name)
    influx_delete("/api/v2/users/#{id}")
  end
rescue StandardError => e
  context.err("Error deleting user state: #{e.message}")
  context.err(e.backtrace)
  nil
end
