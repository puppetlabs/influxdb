# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
class Puppet::Provider::InfluxdbSetup::InfluxdbSetup < Puppet::ResourceApi::SimpleProvider
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
    response = influx_get('/api/v2/setup')[0]
    [
      {
        name: @host,
        use_ssl: @use_ssl,
        port: @port,
        token: @token,
        token_file: @token_file,
        ensure: (response['allowed'] == true) ? 'absent' : 'present',
      },
    ]
  rescue StandardError => e
    context.err("Error getting setup state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")
    body = {
      bucket: should[:bucket],
      org: should[:org],
      username: should[:username],
      password: should[:password].unwrap,
    }
    response = influx_post('/api/v2/setup', JSON.dump(body))
    File.write(should[:token_file], response['auth']['token'])
  rescue StandardError => e
    context.err("Error creating setup state: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, _name, _should)
    context.warning('Unable to update setup resource')
  end

  def delete(context, _name)
    context.warning('Unable to delete setup resource')
  end
end
