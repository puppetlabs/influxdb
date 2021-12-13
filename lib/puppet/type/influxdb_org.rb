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
    name: {
      type: 'String',
      desc: 'Organization to manage in InfluxDB',
      behavior: :namevar,
    },
    members: {
      type: 'Optional[Array[String]]',
      desc: 'A list of users to add as members of the organization',
    },
    description: {
      type: 'Optional[String]',
      desc: 'Optional description for a given org',
    },
  },
)
