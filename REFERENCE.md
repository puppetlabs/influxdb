# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

* [`influxdb`](#influxdb): Installs, configures, and performs initial setup of InfluxDB 2.x
* [`influxdb::profile::toml`](#influxdb--profile--toml): Installs the toml-rb gem inside Puppet server and agent

### Resource types

* [`influxdb_auth`](#influxdb_auth): Manages authentication tokens in InfluxDB
* [`influxdb_bucket`](#influxdb_bucket): Manages InfluxDB buckets
* [`influxdb_dbrp`](#influxdb_dbrp): Manages dbrps, or database and retention policy mappings.  These provide backwards compatibilty for 1.x queries.  Note that these are automatically created by the influxdb_bucket resource, so it isn't necessary to use this resource unless you need to customize them.
* [`influxdb_label`](#influxdb_label): Manages labels in InfluxDB
* [`influxdb_org`](#influxdb_org): Manages organizations in InfluxDB
* [`influxdb_setup`](#influxdb_setup): Manages initial setup of InfluxDB.  It is recommended to use the influxdb::install class instead of this resource directly.
* [`influxdb_user`](#influxdb_user): Manages users in InfluxDB.  Note that currently, passwords can only be set upon creating the user and must be updated manually using the cli.  A user must be added to an organization to be able to log in.

### Functions

* [`influxdb::from_toml`](#influxdb--from_toml)
* [`influxdb::hosts_with_pe_profile`](#influxdb--hosts_with_pe_profile)
* [`influxdb::retrieve_token`](#influxdb--retrieve_token)
* [`influxdb::to_toml`](#influxdb--to_toml)

## Classes

### <a name="influxdb"></a>`influxdb`

Installs, configures, and performs initial setup of InfluxDB 2.x

#### Examples

##### Basic usage

```puppet
include influxdb

class { 'influxdb':
  initial_org    => 'my_org',
  initial_bucket => 'my_bucket',
}
```

#### Parameters

The following parameters are available in the `influxdb` class:

* [`manage_repo`](#-influxdb--manage_repo)
* [`manage_setup`](#-influxdb--manage_setup)
* [`repo_name`](#-influxdb--repo_name)
* [`version`](#-influxdb--version)
* [`archive_source`](#-influxdb--archive_source)
* [`use_ssl`](#-influxdb--use_ssl)
* [`manage_ssl`](#-influxdb--manage_ssl)
* [`use_system_store`](#-influxdb--use_system_store)
* [`ssl_cert_file`](#-influxdb--ssl_cert_file)
* [`ssl_key_file`](#-influxdb--ssl_key_file)
* [`ssl_ca_file`](#-influxdb--ssl_ca_file)
* [`host`](#-influxdb--host)
* [`port`](#-influxdb--port)
* [`initial_org`](#-influxdb--initial_org)
* [`initial_bucket`](#-influxdb--initial_bucket)
* [`admin_user`](#-influxdb--admin_user)
* [`admin_pass`](#-influxdb--admin_pass)
* [`token_file`](#-influxdb--token_file)
* [`repo_gpg_key_id`](#-influxdb--repo_gpg_key_id)
* [`repo_url`](#-influxdb--repo_url)
* [`repo_gpg_key_url`](#-influxdb--repo_gpg_key_url)

##### <a name="-influxdb--manage_repo"></a>`manage_repo`

Data type: `Boolean`

Whether to manage a repository to provide InfluxDB packages.

Default value: `false`

##### <a name="-influxdb--manage_setup"></a>`manage_setup`

Data type: `Boolean`

Whether to perform initial setup of InfluxDB.  This will create an initial organization, bucket, and admin token.

Default value: `true`

##### <a name="-influxdb--repo_name"></a>`repo_name`

Data type: `String`

Name of the InfluxDB repository if using $manage_repo.

Default value: `'influxdb2'`

##### <a name="-influxdb--version"></a>`version`

Data type: `String`

Version of InfluxDB to install.  Changing this is not recommended.

Default value: `'2.6.1'`

##### <a name="-influxdb--archive_source"></a>`archive_source`

Data type: `Variant[String,Boolean[false]]`

URL containing an InfluxDB archive if not installing from a repository or false to disable installing from source.

Default value: `'https://dl.influxdata.com/influxdb/releases/influxdb2-2.6.1-linux-amd64.tar.gz'`

##### <a name="-influxdb--use_ssl"></a>`use_ssl`

Data type: `Boolean`

Whether to use http or https connections.

Default value: `true`

##### <a name="-influxdb--manage_ssl"></a>`manage_ssl`

Data type: `Boolean`

Whether to manage the SSL bundle for https connections.

Default value: `true`

##### <a name="-influxdb--use_system_store"></a>`use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections.

Default value: `false`

##### <a name="-influxdb--ssl_cert_file"></a>`ssl_cert_file`

Data type: `String`

SSL certificate to be used by the influxdb service.

Default value: `"/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem"`

##### <a name="-influxdb--ssl_key_file"></a>`ssl_key_file`

Data type: `String`

Private key used in the CSR for the certificate specified by $ssl_cert_file.

Default value: `"/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem"`

##### <a name="-influxdb--ssl_ca_file"></a>`ssl_ca_file`

Data type: `String`

CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.

Default value: `'/etc/puppetlabs/puppet/ssl/certs/ca.pem'`

##### <a name="-influxdb--host"></a>`host`

Data type: `Stdlib::Host`

fqdn of the host running InfluxDB.

Default value: `$facts['networking']['fqdn']`

##### <a name="-influxdb--port"></a>`port`

Data type: `Stdlib::Port::Unprivileged`

port of the InfluxDB service.

Default value: `8086`

##### <a name="-influxdb--initial_org"></a>`initial_org`

Data type: `String[1]`

Name of the initial organization to use during initial setup.

Default value: `'puppetlabs'`

##### <a name="-influxdb--initial_bucket"></a>`initial_bucket`

Data type: `String[1]`

Name of the initial bucket to use during initial setup.

Default value: `'puppet_data'`

##### <a name="-influxdb--admin_user"></a>`admin_user`

Data type: `String`

Name of the administrative user to use during initial setup.

Default value: `'admin'`

##### <a name="-influxdb--admin_pass"></a>`admin_pass`

Data type: `Sensitive[String[1]]`

Password for the administrative user in Sensitive format used during initial setup.

Default value: `Sensitive('puppetlabs')`

##### <a name="-influxdb--token_file"></a>`token_file`

Data type: `String`

File on disk containing an administrative token.  This class will write the token generated as part of initial setup to this file.
Note that functions or code run in Puppet server will not be able to use this file, so setting $token after setup is recommended.

Default value:

```puppet
$facts['identity']['user'] ? {
    'root'  => '/root/.influxdb_token',
    default => "/home/${facts['identity']['user']}/.influxdb_token"
```

##### <a name="-influxdb--repo_gpg_key_id"></a>`repo_gpg_key_id`

Data type: `String[1]`

ID of the GPG signing key

Default value: `'9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E'`

##### <a name="-influxdb--repo_url"></a>`repo_url`

Data type: `Optional[String]`

URL of the Package repository

Default value: `undef`

##### <a name="-influxdb--repo_gpg_key_url"></a>`repo_gpg_key_url`

Data type: `Stdlib::HTTPSUrl`

URL of the GPG signing key

Default value: `'https://repos.influxdata.com/influxdata-archive_compat.key'`

### <a name="influxdb--profile--toml"></a>`influxdb::profile::toml`

Installs the toml-rb gem inside Puppet server and agent

#### Examples

##### Basic usage

```puppet
include influxdb::profile::toml
```

#### Parameters

The following parameters are available in the `influxdb::profile::toml` class:

* [`version`](#-influxdb--profile--toml--version)
* [`install_options_server`](#-influxdb--profile--toml--install_options_server)
* [`install_options_agent`](#-influxdb--profile--toml--install_options_agent)

##### <a name="-influxdb--profile--toml--version"></a>`version`

Data type: `String`

Version of the toml-rb gem to install

Default value: `'4.0.0'`

##### <a name="-influxdb--profile--toml--install_options_server"></a>`install_options_server`

Data type: `Array[String[1]]`

Pass additional parameters to the puppetserver gem installation

Default value: `[]`

##### <a name="-influxdb--profile--toml--install_options_agent"></a>`install_options_agent`

Data type: `Array[String[1]]`

Pass additional parameters to the puppetserver gem installation

Default value: `[]`

## Resource types

### <a name="influxdb_auth"></a>`influxdb_auth`

Manages authentication tokens in InfluxDB

#### Examples

##### 

```puppet
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
```

#### Properties

The following properties are available in the `influxdb_auth` type.

##### `ensure`

Data type: `Enum[present, absent]`

Whether the token should be present or absent on the target system.

Default value: `present`

##### `force`

Data type: `Boolean`

Recreate resource if immutable property changes

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `name`

Data type: `String`

Name of the token.  Note that InfluxDB does not currently have a human readable identifer for token, so for convinience we use the description property as the namevar of this resource

##### `org`

Data type: `String`

The organization that owns the token

##### `permissions`

Data type: `Array[Hash]`

List of permissions granted by the token

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `status`

Data type: `Enum[active, inactive]`

Status of the token

Default value: `active`

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

##### `user`

Data type: `Optional[String]`

User to scope authorization to

### <a name="influxdb_bucket"></a>`influxdb_bucket`

Manages InfluxDB buckets

#### Examples

##### 

```puppet
influxdb_bucket {'my_bucket':
  ensure  => present,
  org     => 'my_org',
  labels  => ['my_label1', 'my_label2'],
  require => Influxdb_org['my_org'],
}
```

#### Properties

The following properties are available in the `influxdb_bucket` type.

##### `create_dbrp`

Data type: `Boolean`

Whether to create a "database retention policy" mapping to allow for legacy access

Default value: `true`

##### `ensure`

Data type: `Enum[present, absent]`

Whether the bucket should be present or absent on the target system.

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `labels`

Data type: `Optional[Array[String]]`

Labels to apply to the bucket.  For convenience, these will be created automatically without the need to create influxdb_label resources

##### `members`

Data type: `Optional[Array[String]]`

List of users to add as members of the bucket. For convenience, these will be created automatically without the need to create influxdb_user resources

##### `name`

Data type: `String`

Name of the bucket

##### `org`

Data type: `String`

Organization which the buckets belongs to

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `retention_rules`

Data type: `Array`

Rules to determine retention of data inside the bucket

Default value: `[{"type"=>"expire", "everySeconds"=>7776000, "shardGroupDurationSeconds"=>604800}]`

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

### <a name="influxdb_dbrp"></a>`influxdb_dbrp`

This type provides the ability to manage InfluxDB dbrps

#### Examples

##### 

```puppet
influxdb_dbrp {'my_bucket':
  ensure => present,
  org    => 'my_org',
  bucket => 'my_bucket',
  rp     => 'Forever',
}
```

#### Properties

The following properties are available in the `influxdb_dbrp` type.

##### `bucket`

Data type: `String`

The bucket to map to the retention policy to

##### `ensure`

Data type: `Enum[present, absent]`

Whether the dbrp should be present or absent on the target system.

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `is_default`

Data type: `Optional[Boolean]`

Whether this should be the default policy

Default value: `true`

##### `name`

Data type: `String`

Name of the dbrp to manage in InfluxDB

##### `org`

Data type: `String`

Name of the organization that owns the mapping

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `rp`

Data type: `String`

Name of the InfluxDB 1.x retention policy

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

### <a name="influxdb_label"></a>`influxdb_label`

Manages labels in InfluxDB

#### Examples

##### 

```puppet
influxdb_label {'puppetlabs/influxdb':
  ensure  => present,
  org     => 'puppetlabs',
}
```

#### Properties

The following properties are available in the `influxdb_label` type.

##### `ensure`

Data type: `Enum[present, absent]`

Whether the label should be present or absent on the target system.

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `name`

Data type: `String`

Name of the label

##### `org`

Data type: `String`

Organization the label belongs to

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `properties`

Data type: `Optional[Hash]`

Key/value pairs associated with the label

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

### <a name="influxdb_org"></a>`influxdb_org`

Manages organizations in InfluxDB

#### Examples

##### 

```puppet
influxdb_org {'puppetlabs':
  ensure  => present,
}
```

#### Properties

The following properties are available in the `influxdb_org` type.

##### `description`

Data type: `Optional[String]`

Optional description for a given org

##### `ensure`

Data type: `Enum[present, absent]`

Whether the organization should be present or absent on the target system.

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `members`

Data type: `Optional[Array[String]]`

A list of users to add as members of the organization

##### `name`

Data type: `String`

Name of the organization to manage in InfluxDB

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

### <a name="influxdb_setup"></a>`influxdb_setup`

Manages initial setup of InfluxDB.  It is recommended to use the influxdb::install class instead of this resource directly.

#### Examples

##### 

```puppet
influxdb_setup {'<influx_fqdn>':
  ensure     => 'present',
  token_file => <path_to_token_file>,
  bucket     => 'my_bucket',
  org        => 'my_org',
  username   => 'admin',
  password   => 'admin',
}
```

#### Properties

The following properties are available in the `influxdb_setup` type.

##### `bucket`

Data type: `String`

Name of the initial bucket to create

##### `ensure`

Data type: `Enum[present, absent]`

Whether initial setup has been performed.  present/absent is determined by the response from the /setup api

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `org`

Data type: `String`

Name of the initial organization to create

##### `password`

Data type: `Sensitive[String]`

Initial admin user password

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

##### `username`

Data type: `String`

Name of the initial admin user

#### Parameters

The following parameters are available in the `influxdb_setup` type.

* [`name`](#-influxdb_setup--name)

##### <a name="-influxdb_setup--name"></a>`name`

namevar

Data type: `String`

The fqdn of the host running InfluxDB

### <a name="influxdb_user"></a>`influxdb_user`

Manages users in InfluxDB.  Note that currently, passwords can only be set upon creating the user and must be updated manually using the cli.  A user must be added to an organization to be able to log in.

#### Examples

##### 

```puppet
influxdb_user {'bob':
  ensure   => present,
  password => Sensitive('thisisbobspassword'),
}

influxdb_org {'my_org':
  ensure => present,
  members  => ['bob'],
}
```

#### Properties

The following properties are available in the `influxdb_user` type.

##### `ensure`

Data type: `Enum[present, absent]`

Whether the user should be present or absent on the target system.

Default value: `present`

##### `host`

Data type: `Optional[String]`

The host running InfluxDB

##### `name`

Data type: `String`

Name of the user

##### `password`

Data type: `Optional[Sensitive[String]]`

User password

##### `port`

Data type: `Optional[Integer]`

Port used by the InfluxDB service

Default value: `8086`

##### `status`

Data type: `Enum[active, inactive]`

Status of the user

Default value: `active`

##### `token`

Data type: `Optional[Sensitive[String]]`

Administrative token used for authenticating API calls

##### `token_file`

Data type: `Optional[String]`

File on disk containing an administrative token

##### `use_ssl`

Data type: `Boolean`

Whether to enable SSL for the InfluxDB service

Default value: `true`

##### `use_system_store`

Data type: `Boolean`

Whether to use the system store for SSL connections

## Functions

### <a name="influxdb--from_toml"></a>`influxdb::from_toml`

Type: Ruby 4.x API

The influxdb::from_toml function.

#### `influxdb::from_toml(String $file)`

The influxdb::from_toml function.

Returns: `Any`

##### `file`

Data type: `String`



### <a name="influxdb--hosts_with_pe_profile"></a>`influxdb::hosts_with_pe_profile`

Type: Puppet Language

The influxdb::hosts_with_pe_profile function.

#### `influxdb::hosts_with_pe_profile(String $profile)`

The influxdb::hosts_with_pe_profile function.

Returns: `Array`

##### `profile`

Data type: `String`



### <a name="influxdb--retrieve_token"></a>`influxdb::retrieve_token`

Type: Ruby 4.x API

The influxdb::retrieve_token function.

#### `influxdb::retrieve_token(String $uri, String $token_name, String $admin_token_file, Optional[Boolean] $use_system_store)`

The influxdb::retrieve_token function.

Returns: `Any`

##### `uri`

Data type: `String`



##### `token_name`

Data type: `String`



##### `admin_token_file`

Data type: `String`



##### `use_system_store`

Data type: `Optional[Boolean]`



#### `influxdb::retrieve_token(String $uri, String $token_name, Sensitive $admin_token, Optional[Boolean] $use_system_store)`

The influxdb::retrieve_token function.

Returns: `Any`

##### `uri`

Data type: `String`



##### `token_name`

Data type: `String`



##### `admin_token`

Data type: `Sensitive`



##### `use_system_store`

Data type: `Optional[Boolean]`



### <a name="influxdb--to_toml"></a>`influxdb::to_toml`

Type: Ruby 4.x API

The influxdb::to_toml function.

#### `influxdb::to_toml(Hash $hash)`

The influxdb::to_toml function.

Returns: `Any`

##### `hash`

Data type: `Hash`



