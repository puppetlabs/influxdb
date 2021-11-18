# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_org',
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
    #TODO: does this type need to know about this?
    influxdb_host: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
    },
    org: {
      type: 'String',
      desc: 'Organizations to manage in InfluxDB',
      behavior: :namevar,
    },
    desc: {
      type: 'Optional[String]',
      desc: 'Optional description for a given org',
    },
  },
  autorequire: {
    influxdb: '$influxdb_host',
  }
)
