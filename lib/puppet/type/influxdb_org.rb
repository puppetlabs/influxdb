# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_org',
  docs: <<-EOS,
@summary Manages organizations in InfluxDB
@example
  influxdb_org {'puppetlabs':
    ensure  => present,
  }
EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the organization should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the organization to manage in InfluxDB',
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
