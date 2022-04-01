# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_user',
  docs: <<-EOS,
@summary Manages users in InfluxDB.  Note that currently, passwords can only be set upon creating the user and must be updated manually using the cli.  A user must be added to an organization to be able to log in.
@example
  influxdb_user {'bob':
    ensure   => present,
    password => Sensitive('thisisbobspassword'),
  }

  influxdb_org {'my_org':
    ensure => present,
    members  => ['bob'],
  }
EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the user should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the user',
      behavior: :namevar,
    },
    password: {
      type: 'Optional[Sensitive[String]]',
      desc: 'User password',
      behavior: :init_only,
    },
    status: {
      type: 'Enum[active, inactive]',
      desc: 'Status of the user',
      default: 'active',
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
