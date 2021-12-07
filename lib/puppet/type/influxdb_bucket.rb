# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'influxdb_bucket',
  docs: <<-EOS,
@summary a influxdb type
@example
influxdb {
  ensure => 'present',
}

This type provides the ability to manage InfluxDB buckets

EOS
  features: [],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Name of the bucket',
      behavior: :namevar,
    },
    influxdb_host: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
    },
    labels: {
      type: 'Optional[Array[String]]',
      desc: 'Labels applied to the bucket',
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
      type: 'Array[String]',
      desc: 'List of users to add as members of the bucket',
      default: [],
    }
    #TODO: fields present in newer version?
    #description: {
    #  type: 'Optional[String]',
    #  desc: 'Description of the bucket',
    #},
    #schema_type: {
    #  type: 'Enum[implicit, explicit]',
    #  desc: 'What does this do',
    #  default: 'implicit',
    #},
    #type: {
    #  type: 'Enum[user, system]',
    #  desc: 'Bucket type',
    #  default: 'user',
    #},
  },
)
