class influxdb(
  String  $influxdb_host = $facts['fqdn'],
  Integer $influxdb_port = 8086,
  String  $influxdb_repo_name = 'influxdb2',
  String  $telegraf_config_file = '/etc/telegraf/telegraf.conf',
  String  $telegraf_config_dir = '/etc/telegraf/telegraf.d',
  Boolean $manage_influxdb_setup = false,
  Boolean $manage_influxdb_repo = true,
  Boolean $manage_telegraf = true,
  Boolean $use_ssl = true,
  String  $initial_org = 'puppetlabs',
  String  $initial_bucket = 'puppet_data',
  String  $ssl_cert_file = "${facts['puppet_ssldir']}/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="${facts['puppet_ssldir']}/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ="${facts['puppet_ssldir']}/certs/ca.pem",
  Optional[Sensitive[String[1]]] $token = undef,
  String  $token_file = $facts['identity']['user'] ? {
                                      'root'  => '/root/.influxdb_token',
                                      default => "/home/${facts['identity']['user']}/.influxdb_token"
                                    },
){
  unless $token or $manage_influxdb_setup {
    fail('FATAL: unable to manage influxdb resources without either $token or $manage_influxdb_setup')
  }
  # We have to instantiate the base type first to avoid autoloading issues
  influxdb {$influxdb_host:
    ensure        => present,
    influxdb_port => $influxdb_port,
    token         => $token,
    token_file    => $token_file,
    use_ssl       => $use_ssl,
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  if $manage_influxdb_setup {
    unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
      fail("Unable to manage InfluxDB installation on host ${influxdb_host}")
    }
    include influxdb::install
  }

  if $manage_telegraf {
    if $use_ssl {
      file {'/etc/telegraf/cert.pem':
        ensure => present,
        source => "file:///${ssl_cert_file}",
        mode   => '0400',
        owner  => 'telegraf',
      }
      file {'/etc/telegraf/key.pem':
        ensure => present,
        source => "file:///${ssl_key_file}",
        mode   => '0400',
        owner  => 'telegraf',
      }
      file {'/etc/telegraf/ca.pem':
        ensure => present,
        source => "file:///${ssl_ca_file}",
        mode   => '0400',
        owner  => 'telegraf',
      }
    }

    # Create a token with permissions to read and write timeseries data
    # The retrieve_token() function cannot find a token during the catalog compilation which creates it
    #   i.e. it takes two agent runs to become available
    influxdb_auth {"puppet telegraf token":
      ensure        => present,
      org           => $initial_org,
      permissions   => [
        {
          "action"   => "read",
          "resource" => {
            "type"   => "telegrafs"
          }
        },
        {
          "action"   => "write",
          "resource" => {
            "type"   => "telegrafs"
          }
        },
        {
          "action"   => "read",
          "resource" => {
            "type"   => "buckets"
          }
        },
        {
          "action"   => "write",
          "resource" => {
            "type"   => "buckets"
          }
        },
      ]
    }
  }
}
