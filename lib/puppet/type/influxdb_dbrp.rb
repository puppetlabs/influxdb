# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_dbrp',
  docs: <<-EOS,
@summary a influxdb type
@example
influxdb {
  ensure => 'present',
}

This type provides the ability to manage InfluxDB dbrps

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
      desc: 'DBRP manage in InfluxDB',
      behavior: :namevar,
    },
    bucket: {
      type: 'String',
      desc: 'The bucket to map to',
    },
    org: {
      type: 'String',
      desc: 'Name of the organization that owns the mapping',
    },
    #TODO: what do these last fields actually do
    is_default: {
      type: 'Optional[Boolean]',
      desc: 'What does this do',
      default: true,
    },
    #database: {
    #  type: 'String',
    #  desc: 'Name of the InfluxDB 1.x database',
    #},
    rp: {
      type: 'String',
      desc: 'Name of the InfluxDB 1.x retention policy',
    },
  },
)
