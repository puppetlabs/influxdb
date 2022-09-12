# influxdb

## Table of Contents

- [influxdb](#influxdb)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Setup](#setup)
    - [What influxdb affects](#what-influxdb-affects)
    - [Beginning with InfluxDB](#beginning-with-influxdb)
  - [Usage](#usage)
    - [Installation](#installation)
    - [Resource management](#resource-management)
  - [Limitations](#limitations)
- [Supporting Content](#supporting-content)
    - [Articles](#articles)
    - [Videos](#videos)

## Description

This module provides type and provider implementations to manage the resources of an InfluxDB 2.x instance.  Because the [InfluxDB 2.0 api](https://docs.influxdata.com/influxdb/v2.1/api/) provides an interface to these resources, the module is able to manage an InfluxDB server running either on the local machine or remotely.

## Setup

### What influxdb affects

The primary things this module provides are:

* Installation of InfluxDB repositories and packages
* Initial setup of the InfluxDB application
* Configuration and management of InfluxDB resources such as organizations, buckets, etc

The first two items are provided by the `influxdb` class and are restricted to an InfluxDB instance running on the local machine.

InfluxDB resources are managed by the various types and providers. Because we need to be able to enumerate and query resources on either a local or remote machine, the resources accept these parameters with the following defaults:

* host - fqdn
* port - 8086
* token_file - ~/.influxdb_token
* use_ssl - true
* token (optional)

Specifying a `token` in `Sensitive[String]` format is optional, but recommended. See [Beggining with Influxdb](#beginning-with-influxdb) for more info.

Note that you are *not* able to use multiple combinations of these options in a given catalog.  Each provider class will set these values when first instantiated and will use the first value that it finds.  Therefore, it is best to use resource defaults for these parameters in your manifest, e.g.

```
class my_profile::my_class(
  Sensitive[String] $my_token,
){
  Influxdb_bucket {
    token => $my_token,
  }
}
```

See [Usage](#usage) for more information about these use cases.

### Beginning with InfluxDB

The easiest way to get started using this module is by including the `influxdb` class to install and perform initial setup of the application.

```
include influxdb
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

As detailed in [Beginning with influxdb](#Beginning with influxdb), the `influxdb` class manages installation and initial setup of InfluxDB. The following aspects are managed by default:

* InfluxDB repository
* SSL
* Initial setup, including the initial organization and bucket resources
* Token with permissions to read and write Telegrafs and buckets within the initial organization

Note that the admin user and password can be set prior to initial setup, but cannot be managed afterwards.  These must be changed manually using the `influx` cli.

For example, to use a different initial organization and bucket, set the parameters in hiera:

```
influxdb::initial_org: 'my_org'
influxdb::initial_bucket: 'my_bucket'
```

Or use a class-like declaration

```
class {'influxdb':
  initial_org    => 'my_org',
  initial_bucket => 'my_bucket',
}
```

### Resource management

For managing InfluxDB resources, this module provides several types and providers that use the [InfluxDB 2.0 api](https://docs.influxdata.com/influxdb/v2.1/api/).  As mentioned in [What influxdb affects](#what-influxdb-affects), the resources accept parameters to determine how to connect to the host which must be unique per resource type.  For example, to create an organization and bucket and specify a token and non-standard port:

```
class my_profile::my_class(
  Sensitive[String] $token,
){

  influxdb_org {'my_org':
    ensure => present,
    token  => $token,
    port   => 1234,
  }

  influxdb_bucket {'my_bucket':
    ensure  => present,
    org     => 'my_org',
    labels  => ['my_label1', 'my_label2'],
    token  => $token,
    port   => 1234,
  }
}
```

Resource defaults are also a good option:

```
Influxdb_org {
  token => $token,
  port  => 1234,
}

Influxdb_bucket {
  token => $token,
  port  => 1234,
}
```

Note that the `influxdb_bucket` will produce a warning for each specified label that does not currently exist.

If InfluxDB is running locally and there is an admin token saved at `~/.influxdb_token`, it will be used in API calls if the `token` parameter is unset.  However, it is recommended to set the token in hiera as an eyaml-encrypted string.  For example:

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

Hiera data:

```
profile::buckets:
  - 'bucket1'
  - 'bucket2'
  - 'bucket3'
```

Puppet code:

```
class my_profile::my_class{
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




---

# Supporting Content

### Articles

The [Support Knowledge base](https://support.puppet.com/hc/en-us) is a searchable repository for technical information and how-to guides for all Puppet products.

This Module has the following specific Article(s) available:

1. [Manage the installation and configuration of metrics dashboards using the puppetlabs-puppet_operational_dashboards module for Puppet Enterprise ](https://support.puppet.com/hc/en-us/articles/6374662483735)
2. [Monitor the performance of your PuppetDB](https://support.puppet.com/hc/en-us/articles/5918309176727)
3. [High swap usage on your primary server or replica in Puppet Enterprise](https://support.puppet.com/hc/en-us/articles/8118659796759)

### Videos

The [Support Video Playlist](https://youtube.com/playlist?list=PLV86BgbREluWKzzvVulR74HZzMl6SCh3S) is a resource of content generated by the support team

This Module has the following specific video content  available:


1. [Puppet Metrics Overview ](https://youtu.be/LiCDoOUS4hg)
2. [Collecting and Displaying Puppet Metrics](https://youtu.be/13sBMQGDqsA)
3. [Interpreting Puppet Metrics](https://youtu.be/09iDO3DlKMQ)

   
   ---



