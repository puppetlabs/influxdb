class influxdb(
  String  $influxdb_host = $facts['fqdn'],
  Integer $influxdb_port = 8086,
  String  $influxdb_repo_name = 'influxdb2',
  String  $telegraf_config_file = '/etc/telegraf/telegraf.conf',
  String  $telegraf_config_dir = '/etc/telegraf/telegraf.d',
  Boolean $manage_influxdb_setup = true,
  Boolean $manage_influxdb_repo = true,
  Boolean $manage_telegraf_token = true,
  Boolean $manage_telegraf_service = false,
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
  }

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  if $manage_influxdb_setup {
    unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
      fail("Unable to manage InfluxDB installation on host ${influxdb_host}")
    }
    include influxdb::install
  }

  influxdb_user {'Adrian':
    ensure   => present,
    password => Sensitive('puppetlabs'),
  }

  influxdb_org {'puppetlabs':
    ensure      => present,
    description => 'Hi',
    members     => ['Adrian'],
  }

  influxdb_bucket {'foo':
    ensure => present,
    org    => 'puppetlabs',
  }

  influxdb_label {'foo':
    ensure => present,
    org    => 'puppetlabs',
  }

  if $manage_telegraf_token {
    influxdb_auth {"puppet telegraf token":
      ensure        => present,
      org           => 'puppetlabs',
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
      ]
    }
  }
  if $manage_telegraf_service {
    include influxdb::telegraf::configs

    influxdb::telegraf::agent {'puppet_telegraf':
      config_file => $telegraf_config_file,
      config_dir  => $telegraf_config_dir,
      notify      => Exec['puppet_telegraf_daemon_reload'],
    }
  }
}
