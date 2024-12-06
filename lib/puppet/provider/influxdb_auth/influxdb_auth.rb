# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbAuth::InfluxdbAuth < Puppet::ResourceApi::SimpleProvider
  include PuppetX::Puppetlabs::PuppetlabsInfluxdb
  def initialize
    @canonicalized_resources = []
    super
  end

  def canonicalize(context, resources)
    init_attrs(resources)
    resources
  rescue StandardError => e
    context.err("Error canonicalizing resources: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def get(context, names = nil)
    init_auth if @auth.empty?
    get_org_info if @org_hash.empty?
    get_bucket_info if @bucket_hash.empty?

    response = influx_get('/api/v2/authorizations')
    ret = []
    @self_hash = []

    response.each do |r|
      next unless r['authorizations']

      r['authorizations'].select { |s| names.nil? || names.include?(s['description']) }.each do |auth|
        permissions = auth['permissions'].map do |p|
          p['resource'].delete_if { |k, _| ['id', 'orgID'].include?(k) }
          p
        end

        val = {
          name: auth['description'],
          ensure: 'present',
          use_ssl: @use_ssl,
          host: @host,
          port: @port,
          token: @token,
          token_file: @token_file,
          permissions: permissions,
          status: auth['status'],
          user: auth['user'],
          org: auth['org'],
        }

        @self_hash << auth
        ret << val
      end
    end
    ret
  rescue StandardError => e
    context.err("Error getting auth state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    permissions = should[:permissions].map do |p|
      # Permissions can specify a 'name' to restrict them to a specific instance, e.g. individual buckets instead of all buckets
      # If so, find the id from the hash and add it as an 'id' element to the permission
      if p['resource'].key?('name') && !p['resource'].key?('id')
        resname = p['resource']['name']
        restype = p['resource']['type']

        if restype == 'buckets'
          id = id_from_name(@bucket_hash, resname)
          context.err("Unable to find bucket named #{resname}") unless id

          p['resource']['id'] = id
        else
          context.warning('Unable to manage fine-grained permissions for types other than buckets.')
        end
      end
      p
    end

    body = {
      orgID: id_from_name(@org_hash, should[:org]),
      permissions: permissions,
      description: name,
      status: should[:status],
    }

    if should[:user]
      get_user_info if @user_map.empty?
      body['userID'] = id_from_name(@user_map, should[:user])
    end

    influx_post('/api/v2/authorizations', JSON.dump(body))
  rescue StandardError => e
    context.err("Error creating auth state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    self_token = @self_hash.find { |auth| auth['description'] == name }

    # If the status property is unchanged, then a different, immutable property has been changed.
    if self_token['status'] == should[:status]
      if should[:force]
        create(context, name, should)
        delete(context, name)
      else
        context.warning("Unable to update properties other than 'status'.  Please delete and recreate resource with the desired properties")
      end
    else
      auth_id = self_token['id']
      body = {
        status: should[:status],
        description: name,
      }

      influx_patch("/api/v2/authorizations/#{auth_id}", JSON.dump(body))
    end
  rescue StandardError => e
    context.err("Error updating auth state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")

    token_id = @self_hash.find { |auth| auth['description'] == name }.dig('id')
    influx_delete("/api/v2/authorizations/#{token_id}")
  end
rescue StandardError => e
  context.err("Error deleting auth state: #{e.message}")
  context.err(e.backtrace)
  nil
end
