# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/http'
require 'json'
require 'uri'

# Implementation for the influxdb type using the Resource API.
class Puppet::Provider::Influxdb::Influxdb < Puppet::ResourceApi::SimpleProvider
  #TODO: is this a terrible idea
  @@client ||= Puppet.runtime[:http]

  # Hack to set a global URI.  Maybe there's a better way to do this using some kind of prefetch, shared library, etc
  def canonicalize(context, resources)
    @@influxdb_host ||= resources[0][:influxdb_host]
    @@influxdb_port ||= resources[0][:influxdb_port] ? resources[0][:influxdb_port] : 8086
    @@influxdb_uri ||= "http://#{@@influxdb_host}:#{@@influxdb_port}"
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
      response = @@client.get(URI(@@influxdb_uri + "/api/v2/#{name}"), headers: {'Authorization': "Token #{token}"}).body
    else
      response = @@client.get(URI(@@influxdb_uri + "/api/v2/#{name}")).body
    end
    JSON.parse(response)
  end

  def influx_put(name, body)
    if File.file?("#{Dir.home}/.influxdb_token")
      token = File.read("#{Dir.home}/.influxdb_token").chomp
      response = @@client.post(URI(@@influxdb_uri + "/api/v2/#{name}"), body , headers: {'Content-Type' => 'application/json', 'Authorization' => "Token #{token}"}).body
    else
      response = @@client.post(URI(@@influxdb_uri + "/api/v2/#{name}"), body , headers: {'Content-Type' => 'application/json'}).body
    end
    JSON.parse(response)
  end

  # Our HTTP class doesn't have a patch method, so we create the connection and use Net::HTTP manually
  def influx_patch(name, body)
    @@client.connect(URI(@@influxdb_uri + "/api/v2/#{name}")) { |conn|
      request = Net::HTTP::Patch.new(@@influxdb_uri)
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
end
