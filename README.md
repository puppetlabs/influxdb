# influxdb

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with influxdb](#setup)
    * [What influxdb affects](#what-influxdb-affects)
    * [Beginning with influxdb](#beginning-with-influxdb)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module provides type and provider implementations to manage the resources of an InfluxDB 2.x instance.  Because the [InfluxDB 2.0 api](https://docs.influxdata.com/influxdb/v2.1/api/) provides an interface to these resources, the module is able to manage an InfluxDB server running either on the local machine or remotely.

## Setup

### What influxdb affects

The primary things this module provides are:

* Installation of InfluxDB repositories and packages
* Initial setup of the InfluxDB application
* Configuration and management of InfluxDB resources such as organizations, buckets, etc

The first two items are provided by the `influxdb::install` class and are restricted to an InfluxDB instance running on the local machine.

InfluxDB resources are managed by the various types and providers and have a dependency on the `influxdb` class.  This is because we need to be able to enumerate and query resources on either a local or remote machine, and the `influxdb` class provides a kind of "base" resource for the types and providers to inherit.

When managing InfluxDB resources in Puppet code, you will need to include this class as a dependency, for example by including a `require`in your manifest.

```
require influxdb
```

See [Usage](#usage) for more information about these use cases.

### Beginning with influxdb

The easiest way to get started using this module is by including the `influxdb::install` class to install and perform initial setup of the application.

```
include influxdb::install
```

Doing so will:

* Install the `influxdb2` package from either a repository or archive source.
* Configure and start the `influxdb` service
* Perform initial setup of the InfluxDB application, consisting of
    * An initial organization and bucket
    * An administrative token saved to `~/.influxdb_token` by default

The type and provider code is able to use the token saved in this file, provided it is present on the node applying the catalog. However, it is recommended to specify the token via the `influxdb::token` parameter after initial setup.

## Usage

### Installation

As detailed in [Beginning with influxdb](#Beginning with influxdb), the `influxdb::install` class manages installation and initial setup of InfluxDB. The following aspects are managed by default:

* InfluxDB repository
* SSL
* Initial setup, including the initial organization and bucket resources
* Token with permissions to read and write Telegrafs and buckets within the initial organization

Note that the admin user and password can be set prior to initial setup, but cannot be managed afterwards.  These must be changed manually using the `influx` cli.

For example, to use a different initial organization and bucket, set the parameters in hiera:

```
influxdb::install::initial_org: 'my_org'
influxdb::install::initial_bucket: 'my_bucket'
```

Or use a class-like declaration

```
class {'influxdb::install':
  initial_org    => 'my_org',
  initial_bucket => 'my_bucket',
}
```

### Resource management

For managing InfluxDB resources, this module provides several types and providers that use the [InfluxDB 2.0 api](https://docs.influxdata.com/influxdb/v2.1/api/).  The resources have a dependency on an `influxdb` "base" resource which must be included in any catalog that uses them.  For example, to create an organization and bucket:

```
class my_profile::my_influxdb {
  require influxdb

  influxdb_org {'my_org':
    ensure => present,
  }

  influxdb_bucket {'my_bucket':
    ensure  => present,
    org     => 'my_org',
    labels  => ['my_label1', 'my_label2'],
    require => Influxdb_org['my_org'],
  }
}
```

Note that the `influxdb_bucket` will create the labels in the `labels` parameter if they do not already exist.

If InfluxDB is running locally and there is an admin token saved at `~/.influxdb_token`, it will be used in API calls.  However, it is recommended to set the token in hiera as an eyaml-encrypted string.  For example:

```
influxdb::token: '<eyaml_string>'
lookup_options:
   influxdb::token:
     convert_to: "Sensitive"
```

For more complex resource management, here is an example of:

* Looking up a list of buckets
* Creating a hash with `ensure => present` for each bucket
* Creating the bucket resources with a default org of `myorg` and retention policy of 30 days.

```
  $buckets = lookup('profile::buckets')
  $bucket_hash = $buckets.reduce({}) |$memo, $bucket| {
    $tmp = $memo.merge({"$bucket" => { "ensure" => present } })
    $tmp
  }

  create_resources(
    influxdb_bucket,
    $bucket_hash,
    {
      'org'        => 'myorg',
      retention_rules => [{
        'type' => 'expire',
        'everySeconds' => 2592000,
        'shardGroupDurationSeconds' => 604800,
      }]
    }
  )
```

## Limitations

This module is incompatible with InfluxDB 1.x.  Migrating data from 1.x to 2.x must be done manually.  For more information see [here](https://docs.influxdata.com/influxdb/v2.1/upgrade/v1-to-v2/).
