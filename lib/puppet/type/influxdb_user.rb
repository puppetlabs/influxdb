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
  features: [],
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
      behavior: :parameter,
    },
    status: {
      type: 'Enum[active, inactive]',
      desc: 'Status of the user',
      default: 'active',
    },
  },
)
