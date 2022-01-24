class influxdb::install(
  Boolean $manage_repo = true,
  Boolean $manage_setup = true,
  Boolean $manage_initial_resources = true,
  Boolean $manage_telegraf_token = true,

  String  $influxdb_repo_name = 'influxdb2',
  String  $influxdb_version = '2.1.1',
  String  $archive_source = 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.1.1-linux-amd64.tar.gz',

  Boolean $use_ssl = $influxdb::use_ssl,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ="/etc/puppetlabs/puppet/ssl/certs/ca.pem",


  String  $influxdb_host = $influxdb::influxdb_host,
  String  $initial_org = 'puppetlabs',
  String  $initial_bucket = 'puppet_data',

  String  $admin_user = 'admin',
  Sensitive[String[1]] $admin_pass = Sensitive('puppetlabs'),
  String  $token_file = $influxdb::token_file,

){
  require influxdb

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  if $manage_setup {
    unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
      fail("Unable to manage InfluxDB installation on host ${influxdb_host}")
    }
  }

  # If we are managing the repository, set it up and install the package with a require on the repo
  if $manage_repo and $facts['os']['family'] in ['Redhat'] {
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
  # If not managing the repo, install the package from archive source
  elsif $archive_source {
    file {['/etc/influxdb', '/opt/influxdb', '/etc/influxdb/scripts']:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }
    file { '/var/lib/influxdb':
      ensure => directory,
      owner  => 'influxdb',
      group  => 'influxdb',
    }

    $default_dir = $facts['os']['family'] ? {
      'Debian' => '/etc/default',
      default  => '/etc/sysconfig',
    }
    file {'/etc/systemd/system/influxdb.service':
      ensure  => present,
      content => epp('influxdb/influxdb_service.epp', env_file => "${base_dir}/influxdb2"),
    }

    archive { '/tmp/influxdb.tar.gz':
      ensure          => present,
      extract         => true,
      extract_command => 'tar xfz %s --strip-components=1',
      extract_path    => '/opt/influxdb',
      source          => $archive_source,
      cleanup         => true,
      require         => File['/etc/influxdb', '/opt/influxdb'],
    }

    group { 'influxdb':
      ensure => present,
    }
    user { 'influxdb':
      ensure => present,
      gid    => 'influxdb',
    }

    file {'/etc/influxdb/scripts/influxd-systemd-start.sh':
      ensure => present,
      source => 'puppet:///modules/influxdb/influxd-systemd-start.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '775',
      notify => Service['influxdb'],
    }
  }

  # Otherwise, assume we have a source for the package
  else {
    package {'influxdb2':
      ensure  => installed,
    }
  }

  if $use_ssl {
    file {'/etc/influxdb/cert.pem':
      ensure => present,
      source => "file:///${ssl_cert_file}",
      notify => Service['influxdb'],
    }
    file {'/etc/influxdb/key.pem':
      ensure => present,
      source => "file:///${ssl_key_file}",
      notify => Service['influxdb'],
    }
    file {'/etc/influxdb/ca.pem':
      ensure => present,
      source => "file:///${ssl_ca_file}",
      notify => Service['influxdb'],
    }
    file {"/etc/systemd/system/influxdb.service.d":
      ensure => directory,
      owner  => 'influxdb',
      notify => Service['influxdb'],
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
      notify => Service['influxdb'],
    }
  }

  service {'influxdb':
    ensure  => running,
    enable  => true,
  }

  if $manage_setup {
    influxdb_setup {$influxdb_host:
      ensure     => 'present',
      token_file => $token_file,
      bucket     => $initial_bucket,
      org        => $initial_org,
      username   => $admin_user,
      password   => $admin_pass,
      require    => Service['influxdb'],
    }

    if $manage_telegraf_token {
      # Create a token with permissions to read and write timeseries data
      # The influxdb::retrieve_token() function cannot find a token during the catalog compilation which creates it
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
        ],
        require    => Service['influxdb'],
      }
    }

    if $manage_initial_resources {
      influxdb_label {'puppetlabs/influxdb':
        ensure  => present,
        org     => $initial_org,
        require => Influxdb_setup[$influxdb_host],
      }

      influxdb_bucket {$initial_bucket:
        ensure  => present,
        org     => $initial_org,
        labels => ['puppetlabs/influxdb'],
        require => [Influxdb_setup[$influxdb_host], Influxdb_label['puppetlabs/influxdb']],
      }

      influxdb_org {$initial_org:
        ensure => present,
        require => [Influxdb_setup[$influxdb_host], Influxdb_label['puppetlabs/influxdb']],
      }
    }
  }
}
