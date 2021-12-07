class influxdb::install(
  Boolean $manage_influxdb_repo = $influxdb::manage_influxdb_repo,
  Boolean $manage_telegraf_service = $influxdb::manage_telegraf_service,
  String  $influxdb_host = $influxdb::influxdb_host,
  String  $influxdb_repo_name = $influxdb::influxdb_repo_name,
  String  $initial_org = 'puppetlabs',
  Hash    $output_defaults = {'bucket' => 'puppet', 'organization' => 'puppetlabs', 'token' => '$INFLUX_TOKEN'},
  String  $initial_bucket = 'puppet',
  String  $admin_user = 'admin',
  String  $admin_pass = 'puppetlabs',
){
  # If we are managing the repository, set it up and install the package with a require on the repo
  if $manage_influxdb_repo {
    #TODO: other distros
    case $facts['os']['family'] {
      'RedHat': {
        $dist = $facts['os']['name'] ? {
          'CentOS' => 'centos',
          default  => 'rhel',
        }
        yumrepo {$influxdb_repo_name:
          ensure   => 'present',
          name     => $influxdb_repo_name,
          baseurl  => "https://repos.influxdata.com/$dist/\$releasever/\$basearch/stable",
          gpgkey   => 'https://repos.influxdata.com/influxdb2.key https://repos.influxdata.com/influxdb.key',
          enabled  => '1',
          gpgcheck => '1',
          target   => '/etc/yum.repos.d/influxdb2.repo',
        }
      }
    }
    package {'influxdb2':
      ensure  => installed,
      require => Yumrepo[$influxdb_repo_name],
    }
    if $manage_telegraf_service {
      package {'telegraf':
        ensure  => installed,
        require => Yumrepo[$influxdb_repo_name],
      }
    }
  }
  # Otherwise, just install the package
  else {
    package {'influxdb2':
      ensure  => installed,
    }
    package {'telegraf':
      ensure  => installed,
    }
  }

  service {'influxdb':
    ensure  => running,
    enable  => true,
    require => Package['influxdb2'],
  }

  influxdb_setup {$influxdb_host:
    ensure        => 'present',
  }
}
