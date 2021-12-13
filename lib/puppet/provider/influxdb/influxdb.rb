# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/http'
require 'json'
require 'uri'
require 'pry'

# Implementation for the influxdb type using the Resource API.
class Puppet::Provider::Influxdb::Influxdb < Puppet::ResourceApi::SimpleProvider
  # Add these variables to this class' eigenclass, i.e. the class itself, as opposed to instances of the class
  # Ideally we'd set these in initialize() as regular instance variables, but we don't know what
  #   the resources will be during initialization
  class << self
    attr_accessor :influxdb_host, :influxdb_port, :token, :token_file
  end
  attr_accessor :telegraf_hash, :user_map, :label_hash, :auth, :bucket_hash

  def initialize()
    @client = Puppet.runtime[:http]
    @org_hash, @telegraf_hash, @label_hash, @user_map, @bucket_hash = [], [], [], [], []
    @auth = {}
  end

  # Make class instance variables available as instance variables to whichever object calls this method
  # For subclasses which call super, the instance variables will be part of their scope
  def init_attrs()
    @influxdb_host = Puppet::Provider::Influxdb::Influxdb.influxdb_host
    @influxdb_port = Puppet::Provider::Influxdb::Influxdb.influxdb_port
    @influxdb_uri = "http://#{@influxdb_host}:#{@influxdb_port}"
  end

  #TODO: don't run this for every type if data already there
  def init_data()
    if influx_setup
      get_org_info
      get_user_info
      get_telegraf_info
      get_label_info
      get_bucket_info
    end
  end

  def init_auth()
    @auth = if Puppet::Provider::Influxdb::Influxdb.token
              {Authorization: "Token #{Puppet::Provider::Influxdb::Influxdb.token.unwrap}"}
            elsif Puppet::Provider::Influxdb::Influxdb.token_file && File.file?(Puppet::Provider::Influxdb::Influxdb.token_file)
              _token = File.read(Puppet::Provider::Influxdb::Influxdb.token_file)
              {Authorization: "Token #{_token}"}
            else
              {}
            end
  end

  # Helper methods to map names to internal IDs
  def id_from_name(hashes, name)
    hashes.select {|user| user['name'] == name}.map { |user| user['id'] }.first
  end
  #JSON.parse(response.body)
  def name_from_id(hashes, id)
    hashes.select {|user| user['id'] == id}.map { |user| user['name'] }.first
  end

  # Puppet calls this method before get(), so we can use it to set instance variables before querying state
  # This is needed because all of our resources come from a remote source
  # This method seems to be called twice, once with parameters and once without.  Why?
  def canonicalize(context, resources)
    self.class.influxdb_host = resources[0][:name]
    self.class.influxdb_port = resources[0][:influxdb_port]

    if resources[0][:token]
      self.class.token = resources[0][:token]
    elsif resources[0][:token_file]
      self.class.token_file = resources[0][:token_file]
    end

    init_attrs()
    resources
  end

  def get(context)
    init_auth()
    # Cache gobal data if InfluxDB is up
    init_data()

    [
      {
        name: @influxdb_host,
        influxdb_port: @influxdb_port,
        ensure: 'present',
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

  def influx_get(name, params:)
    response = @client.get(URI(@influxdb_uri + name), headers: @auth)
    if response.success?
      JSON.parse(response.body ? response.body : '{}')
    # We may receive a 404 if the api path doesn't exists, such as a /links request for an org with no labels
    # We won't consider this a fatal error
    elsif response.code == 404
      {}
    else
      raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}"
    end
  end

  def influx_post(name, body)
    response = @client.post(URI(@influxdb_uri + name), body , headers: @auth.merge({'Content-Type' => 'application/json'}))
    if response.success?
      JSON.parse(response.body ? response.body : '{}')
    else
      raise Puppet::DevError, "Received HTTP code '#{response.code}' with message '#{response.reason}'"
    end
  end

  def influx_put(name, body)
    response = @client.put(URI(@influxdb_uri + name), body , headers: @auth)
    if response.success?
      JSON.parse(response.body ? response.body : '{}')
    else
      raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}"
    end
  end

  # Our HTTP class doesn't have a patch method, so we create the connection and use Net::HTTP manually
  def influx_patch(name, body)
    @client.connect(URI(@influxdb_uri)) { |conn|
      request = Net::HTTP::Patch.new(@influxdb_uri + name)
      request['Content-Type'] = 'application/json'

      request['Authorization'] = @auth[:Authorization]

      request.body = body
      response = conn.request(request)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body ? response.body : '{}')
      else
        raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}"
      end
    }
  end

  def influx_delete(name)
    response = @client.delete(URI(@influxdb_uri + name), headers: @auth)
    if response.success?
      JSON.parse(response.body ? response.body : '{}')
    else
      raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}"
    end
  end

  def influx_setup()
    begin
      response = influx_get('/api/v2/setup', params: {})
      response['allowed'] == false
    rescue Exception => e
      false
    end
  end

  def get_org_info()
    response = influx_get('/api/v2/orgs', params: {})
    if response['orgs']
      response['orgs'].each { |org|
        process_links(org, org['links'])
        @org_hash << org
      }
    end
  end

  def get_bucket_info()
    response = influx_get('/api/v2/buckets', params: {})
    if response['buckets']
      response['buckets'].each { |bucket|
        process_links(bucket, bucket['links'])
        @bucket_hash << bucket
      }
    end
  end

  def get_telegraf_info()
    response = influx_get('/api/v2/telegrafs', params: {})

    if response['configurations']
      response['configurations'].each { |telegraf|
        process_links(telegraf, telegraf['links'])
        @telegraf_hash << telegraf
      }
    end
  end

  def get_user_info()
    response = influx_get('/api/v2/users', params: {})
    if response['users']
      response['users'].each { |user|
        process_links(user, user['links'])
        @user_map << user
      }
    end
  end

  def get_label_info()
    response = influx_get('/api/v2/labels', params: {})
    @label_hash = response['labels'] ? response['labels'] : []
  end

  def process_links(org, links)
    # For each org hash returned by the api, traverse the 'links' entries and add an element to the hash
    # For example, given an org 'puppetlabs' with {"links" => ["buckets": "/api/v2/buckets?org=puppetlabs"]}
    #   add the results of the "buckets" api call to a "buckets" key
    links.each { |k,v|
      next if k == "self" or k == 'write'
      response = influx_get(v, params: {})
      org[k] = response
    }
  end
end
