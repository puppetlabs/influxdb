# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_user',
  docs: <<-EOS,
@summary a influxdb type
@example
influxdb {
  ensure => 'present',
}

This type provides the ability to manage InfluxDB organizations

EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the user',
      behavior: :namevar,
    },
    influxdb_host: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
    },
    password: {
      type: 'Optional[Sensitive[String]]',
      desc: 'User password',
      behavior: :parameter,
    },
    status: {
      type: 'String',
      desc: 'Status of the user',
      default: 'active',
    },
    #orgs: {
    #  type: 'Array',
    #  desc: 'Organizations to add the user to',
    #},
  },
)
