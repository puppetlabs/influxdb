# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_label',
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
      desc: 'Name of the label',
      behavior: :namevar,
    },
    influxdb_host: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
    },
    org: {
      type: 'String',
      desc: 'Organization the label belongs to',
    },
    properties: {
      type: 'Optional[Hash]',
      desc: 'Key/value pairs associated with the label',
    },
  },
)
