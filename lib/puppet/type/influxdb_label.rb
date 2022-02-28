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
  features: ['canonicalize'],
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
    host: {
      type: 'Optional[String]',
      desc: 'The host running InfluxDB',
      behavior: :parameter
    },
    port: {
      type: 'Optional[Integer]',
      desc: 'Port used by the InfluxDB service',
      default: 8086,
      behavior: :parameter,
    },
    token: {
      type: 'Optional[Sensitive[String]]',
      desc: 'Administrative token used for authenticating API calls',
      behavior: :parameter,
    },
    token_file: {
      type: 'Optional[String]',
      desc: 'File on disk containing an administrative token',
      behavior: :parameter,
    },
    use_ssl: {
      type: 'Boolean',
      desc: 'Whether to enable SSL for the InfluxDB service',
      default: true,
      behavior: :parameter,
    }
  },
)
