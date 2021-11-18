# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb',
  docs: <<-EOS,
@summary a influxdb type
@example
influxdb {
  ensure => 'present',
}

This type is an abstraction to represent the entirety of the InfluxDB stack as installed on a given system.  ensure => present is determined by whether initial setup has been performed, e.g. if the /setup api returns allowed: false.

EOS
  features: ['canonicalize'],
  attributes: {
    #ensure: {
    #  type: 'Enum[present, absent]',
    #  desc: 'Whether this resource should be present or absent on the target system.',
    #  default: 'present',
    #},
    influxdb_host: {
      type: 'String',
      desc: 'The host running InfluxDB',
      behaviour: :namevar,
    },
    influxdb_port: {
      type: 'Optional[Integer]',
      desc: 'Port used by the InfluxDB service',
      default: 8086,
    }
  },
)
