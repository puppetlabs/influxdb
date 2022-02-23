# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_bucket',
  docs: <<-EOS,
@summary Manages InfluxDB buckets
@example
  influxdb_bucket {'my_bucket':
    ensure  => present,
    org     => 'my_org',
    labels  => ['my_label1', 'my_label2'],
    require => Influxdb_org['my_org'],
  }
EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the bucket should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the bucket',
      behavior: :namevar,
    },
    labels: {
      type: 'Optional[Array[String]]',
      desc: 'Labels to apply to the bucket.  For convenience, these will be created automatically without the need to create influxdb_label resources',
    },
    org: {
      type: 'String',
      desc: 'Organization which the buckets belongs to',
    },
    retention_rules: {
      type: 'Array',
      desc: 'Rules to determine retention of data inside the bucket',
      default: [{
        'type' => 'expire',
        'everySeconds' => 0,
        'shardGroupDurationSeconds' => 604800,
      }]
    },
    members: {
      type: 'Optional[Array[String]]',
      desc: 'List of users to add as members of the bucket. For convenience, these will be created automatically without the need to create influxdb_user resources',
    },
    create_dbrp: {
      type: 'Boolean',
      desc: 'Whether to create a "database retention policy" mapping to allow for legacy access',
      default: true,
    },
  },
)
