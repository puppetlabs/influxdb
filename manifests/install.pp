class influxdb::install(
  Boolean $manage_influxdb_repo = $influxdb::manage_influxdb_repo,
  Boolean $manage_telegraf = $influxdb::manage_telegraf,
  Boolean $use_ssl = $influxdb::use_ssl,
  String $ssl_cert_file = $influxdb::ssl_cert_file,
  String $ssl_key_file = $influxdb::ssl_key_file,
  String $ssl_ca_file = $influxdb::ssl_ca_file,
  String  $influxdb_host = $influxdb::influxdb_host,
  String  $influxdb_repo_name = $influxdb::influxdb_repo_name,
  String  $initial_org = $influxdb::initial_org,
  String  $initial_bucket = $influxdb::initial_bucket,
  String  $admin_user = 'admin',
  Sensitive[String[1]] $admin_pass = Sensitive('puppetlabs'),
  String  $token_file = $influxdb::token_file,
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
  }
  # Otherwise, just install the package
  else {
    package {'influxdb2':
      ensure  => installed,
    }
  }

  if $use_ssl {
    File {
      mode    => '0400',
      owner   => 'influxdb',
      require => Package['influxdb2'],
    }

    file {'/etc/influxdb/cert.pem':
      ensure => present,
      source => "file:///${ssl_cert_file}",
    }
    file {'/etc/influxdb/key.pem':
      ensure => present,
      source => "file:///${ssl_key_file}",
    }
    file {'/etc/influxdb/ca.pem':
      ensure => present,
      source => "file:///${ssl_ca_file}",
    }
    file {"/etc/systemd/system/influxdb.service.d":
      ensure => directory,
      owner  => 'influxdb',
    }
    file {"/etc/systemd/system/influxdb.service.d/override.conf":
      ensure  => file,
      #TODO: epp necessary?
      content => epp(
        'influxdb/influxdb_dropin.epp',
        {
          cert => '/etc/influxdb/cert.pem',
          key  => '/etc/influxdb/key.pem',
        }
      ),
    }
  }

  service {'influxdb':
    ensure  => running,
    enable  => true,
    require => Package['influxdb2'],
  }

  influxdb_setup {$influxdb_host:
    ensure     => 'present',
    token_file => $token_file,
    bucket   => $initial_bucket,
    org      => $initial_org,
    username => $admin_user,
    password => $admin_pass,
  }

  influxdb_label {'puppetlabs/influxdb':
    ensure  => present,
    org     => $initial_org,
    require => Influxdb_setup[$influxdb_host],
  }

  influxdb_bucket {$initial_bucket:
    ensure  => present,
    org     => $initial_org,
    labels => ['puppetlabs/influxdb'],
    require => Influxdb_setup[$influxdb_host],
  }
}
