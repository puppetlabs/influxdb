# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb',
  docs: <<-EOS,
@summary Base resource dependency for all other influxdb_* types and providers.  This resource should not be used directly, but rather by requiring the influxdb class.
@example require influxdb
EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Because this resource is an abstraction, its ensure property is always "present".  It is used to provide the ensurable property so that it functions as a type/provider',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'The host running InfluxDB',
      behaviour: :namevar,
    },
    influxdb_port: {
      type: 'Integer',
      desc: 'Port used by the InfluxDB service',
      default: 8086,
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
    }
  },
)
