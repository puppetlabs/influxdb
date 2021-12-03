# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/http'
require 'json'
require 'uri'

# Implementation for the influxdb type using the Resource API.
class Puppet::Provider::Influxdb::Influxdb < Puppet::ResourceApi::SimpleProvider
  #TODO: is this a terrible idea
  @@client ||= Puppet.runtime[:http]
  @@org_hash = []
  @@telegraf_hash = []

  # Hack to set a global URI.  Maybe there's a better way to do this using some kind of prefetch, shared library, etc
  def canonicalize(context, resources)
    @@influxdb_host ||= resources[0][:influxdb_host]
    @@influxdb_port ||= resources[0][:influxdb_port] ? resources[0][:influxdb_port] : 8086
    @@influxdb_uri ||= "http://#{@@influxdb_host}:#{@@influxdb_port}"

    if ping
      get_org_info
      get_telegraf_info
    end

    resources
  end

  def get(context)
    [
      {
        influxdb_host: @@influxdb_host,
        influxdb_port: @@influxdb_port,
      },
    ]
  end

  # This base provider doesn't have any resources to manage at the moment.  Setup is done via the influxdb_setup type
  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

  #TODO: refactor into proper auth class
  #TODO: error checking
  def influx_get(name, params:)
    if File.file?("#{Dir.home}/.influxdb_token")
      token = File.read("#{Dir.home}/.influxdb_token").chomp
      response = @@client.get(URI(@@influxdb_uri + name), headers: {'Authorization': "Token #{token}"})
    else
      response = @@client.get(URI(@@influxdb_uri + name))
    end
    if response.success?
      JSON.parse(response.body)
    else
      {}
    end
  end

  def influx_post(name, body)
    if File.file?("#{Dir.home}/.influxdb_token")
      token = File.read("#{Dir.home}/.influxdb_token").chomp
      response = @@client.post(URI(@@influxdb_uri + name), body , headers: {'Content-Type' => 'application/json', 'Authorization' => "Token #{token}"}).body
    else
      response = @@client.post(URI(@@influxdb_uri + name), body , headers: {'Content-Type' => 'application/json'}).body
    end
    JSON.parse(response)
  end

  def influx_put(name, body)
    if File.file?("#{Dir.home}/.influxdb_token")
      token = File.read("#{Dir.home}/.influxdb_token").chomp
      response = @@client.put(URI(@@influxdb_uri + name), body , headers: {'Content-Type' => 'application/json', 'Authorization' => "Token #{token}"}).body
    else
      response = @@client.put(URI(@@influxdb_uri + name), body , headers: {'Content-Type' => 'application/json'}).body
    end
    JSON.parse(response)
  end

  # Our HTTP class doesn't have a patch method, so we create the connection and use Net::HTTP manually
  def influx_patch(name, body)
    @@client.connect(URI(@@influxdb_uri)) { |conn|
      request = Net::HTTP::Patch.new(@@influxdb_uri + name)
      request['Content-Type'] = 'application/json'

      if File.file?("#{Dir.home}/.influxdb_token")
        token = File.read("#{Dir.home}/.influxdb_token").chomp
        request['Authorization'] = "Token #{token}"
      end
      request.body = body

      response = conn.request(request)
      JSON.parse(response.body)
    }
  end

  def influx_delete(name)
    if File.file?("#{Dir.home}/.influxdb_token")
      token = File.read("#{Dir.home}/.influxdb_token").chomp
      response = @@client.delete(URI(@@influxdb_uri + name), headers: {'Content-Type' => 'application/json', 'Authorization' => "Token #{token}"})
    else
      response = @@client.delete(URI(@@influxdb_uri + name), headers: {'Content-Type' => 'application/json'})
    end
    #JSON.parse(response.body)
  end

  def ping()
    begin
      response = influx_get('/api/v2/ping', params: {})
    #TODO: way better exception handling
    rescue Exception => e
      false
    else
      true
    end
  end

  def get_org_info()
    # Only run this method once per catalog compilation
    if @@org_hash.empty?
      response = influx_get('/api/v2/orgs', params: {})
      if response['orgs']
        response['orgs'].each { |org|
          process_links(org, org['links'])
          @@org_hash << org
        }
      end
    end
  end

  def get_telegraf_info()
    # Only run this method once per catalog compilation
    if @@telegraf_hash.empty?
      response = influx_get('/api/v2/telegrafs', params: {})

      if response['configurations']
        response['configurations'].each { |telegraf|
          process_links(telegraf, telegraf['links'])
          @@telegraf_hash << telegraf
        }
      end

    end
  end

  def process_links(org, links)
    # For each org hash returned by the api, traverse the 'links' entries and add an element to the hash
    # For example, given an org 'puppetlabs' with {"links" => ["buckets": "/api/v2/buckets?org=puppetlabs"]}
    #   add the results of the "buckets" api call to a "buckets" key
    links.each { |k,v|
      next if k == "self"
      org[k] = influx_get(v, params: {})
    }

  end

  def org_id_from_name(name)
    @@org_hash.map { |org| org['id'] }.first
  end
  def org_name_from_id(id)
    @@org_hash.map { |org| org['name'] }.first
  end

  def telegraf_id_from_name(name)
    @@telegraf_hash.map { |telegraf| telegraf['id'] }.first
  end
  def telegraf_name_from_id(id)
    @@telegraf_hash.map { |telegraf| telegraf['name'] }.first
  end

end
