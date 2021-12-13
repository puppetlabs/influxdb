# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_auth',
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
    name: {
      type: 'String',
      desc: 'Description of the token',
      behavior: :namevar,
    },
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    status: {
      type: 'Enum[active, inactive]',
      desc: 'Status of the token',
      default: 'active',
    },
    org: {
      type: 'String',
      desc: 'The organization that owns the token',
    },
    user: {
      type: 'Optional[String]',
      desc: 'User to scope authorization to',
    },
    permissions: {
      type: 'Array[Hash]',
      desc: 'List of permissions granted by the authorization',
    },
  },
)
