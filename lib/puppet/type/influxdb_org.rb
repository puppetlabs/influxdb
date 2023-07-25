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
  features: ['canonicalize', 'simple_get_filter'],
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
    },
    use_system_store: {
      type: 'Boolean',
      desc: 'Whether to use the system store for SSL connections',
      default: false,
      behavior: :parameter,
    },
    ca_bundle: {
      type: 'String',
      desc: 'Path to the CA bundle to use if using the system store',
      default: '',
      behavior: :parameter,
    },
  },
)
