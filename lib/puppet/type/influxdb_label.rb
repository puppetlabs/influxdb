# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_label',
  docs: <<-EOS,
@summary Manages labels in InfluxDB
@example
  influxdb_label {'puppetlabs/influxdb':
    ensure  => present,
    org     => 'puppetlabs',
  }
EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the label should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the label',
      behavior: :namevar,
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
