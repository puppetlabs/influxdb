# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'telegraf_config',
  docs: <<-EOS,
@summary a influxdb type
@example
influxdb {
  ensure => 'present',
}

This type provides the ability to manage Telegraf configurations

EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    influxdb_host: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
    },
    name: {
      type: 'String',
      desc: 'Name of the Telegraf config to manage in InfluxDB',
      behavior: :namevar,
    },
    description: {
      type: 'Optional[String]',
      desc: 'Optional description for a given org',
    },
    config: {
      type: 'Optional[Hash]',
      desc: 'Hash representation of a Telegraf config',
    },
    org: {
      type: 'String',
      desc: 'Name of the InfluxDB organization in which to store Telegraf configuration',
    },
    labels: {
      type: 'Optional[Array[String]]',
      desc: 'Labels applied to the Telegraf config',
    },
    #TODO: manage this in the provider code?  e.g. use a String 'bucket' instead of a metadata hash
    metadata: {
      type: 'Hash',
      desc: 'Buckets go here',
    },
    #TODO: only accept a config hash or URI
    #TODO: how would this actually work
    source: {
      type: 'Optional[URI]',
      desc: 'URI which stores the complete configuration, e.g. an http server',
      behavior: :parameter,
    }
  },
)
