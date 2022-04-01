# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_dbrp',
  docs: <<-EOS,
@summary Manages dbrps, or database and retention policy mappings.  These provide backwards compatibilty for 1.x queries.  Note that these are automatically created by the influxdb_bucket resource, so it isn't necessary to use this resource unless you need to customize them.
@example
  influxdb_dbrp {'my_bucket':
    ensure => present,
    org    => 'my_org',
    bucket => 'my_bucket',
    rp     => 'Forever',
  }

This type provides the ability to manage InfluxDB dbrps

EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the dbrp should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the dbrp to manage in InfluxDB',
      behavior: :namevar,
    },
    bucket: {
      type: 'String',
      desc: 'The bucket to map to the retention policy to',
      behavior: :init_only,
    },
    org: {
      type: 'String',
      desc: 'Name of the organization that owns the mapping',
      behavior: :init_only,
    },
    is_default: {
      type: 'Optional[Boolean]',
      desc: 'Whether this should be the default policy',
      default: true,
    },
    rp: {
      type: 'String',
      desc: 'Name of the InfluxDB 1.x retention policy',
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
