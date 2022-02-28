# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../shared/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::InfluxdbSetup::InfluxdbSetup <Puppet::ResourceApi::SimpleProvider
  include PuppetlabsInfluxdb
  def initialize
    @canonicalized_resources = []
    super
  end

  def canonicalize(context, resources)
    init_attrs(resources)
    resources
  end

  def get(context)
    response = influx_get('/api/v2/setup')
    [
      {
        name: @host,
        ensure: response['allowed'] == true ? 'absent' : 'present',
      },
    ]
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
  end

  def update(context, _name, _should)
    context.warning('Unable to update setup resource')
  end

  def delete(context, _name)
    context.warning('Unable to delete setup resource')
  end
end
