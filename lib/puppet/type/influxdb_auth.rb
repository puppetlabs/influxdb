# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_auth',
  docs: <<-EOS,
@summary Manages authentication tokens in InfluxDB
@example
  influxdb_auth {"telegraf read token":
    ensure        => present,
    org           => 'my_org'
    permissions   => [
      {
        "action"   => "read",
        "resource" => {
          "type"   => "telegrafs"
        }
      },
    ],
  }
EOS
  features: ['canonicalize'],
  attributes: {
    name: {
      type: 'String',
      desc: 'Name of the token.  Note that InfluxDB does not currently have a human readable identifer for token, so for convinience we use the description property as the namevar of this resource',
      behavior: :namevar,
    },
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the token should be present or absent on the target system.',
      default: 'present',
    },
    status: {
      type: 'Enum[active, inactive]',
      desc: 'Status of the token',
      default: 'active',
    },
    org: {
      type: 'String',
      desc: 'The organization that owns the token',
    },
    user: {
      type: 'Optional[String]',
      desc: 'User to scope authorization to',
    },
    permissions: {
      type: 'Array[Hash]',
      desc: 'List of permissions granted by the token',
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
