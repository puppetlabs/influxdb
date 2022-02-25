# @summary Installs, configures, and performs initial setup of InfluxDB 2.x
# @example Basic usage
#   include influxdb::install
#
#   class {'influxdb::install':
#     initial_org => 'my_org',
#     initial_bucket => 'my_bucket',
#   }
# @param manage_repo
#   Whether to manage a repository to provide InfluxDB packages.  Defaults to true
# @param manage_setup
#   Whether to perform initial setup of InfluxDB.  This will create an initial organization, bucket, and admin token.  Defaults to true.
# @param manage_initial_resources
#   Whether to manage the initial organization and bucket resources.  Defaults to true.
# @param manage_telegraf_token
#   Whether to create and manage a Telegraf token.  The token will have permissions to read and write all buckets and telegrafs in the initial organization
# @param repo_name
#   Name of the InfluxDB repository if using $manage_repo.  Defaults to influxdb2
# @param version
#   Version of InfluxDB to install.  Changing this is not recommended.
# @param archive_source
#   URL containing an InfluxDB archive if not installing from a repository.  Defaults to version 2-2.1.1 on amd64 architechture.
# @param use_ssl
#   Whether to use http or https connections.  Defaults to true (https).
# @param manage_ssl
#   Whether to manage the SSL bundle for https connections.  Defaults to true.
# @param ssl_cert_file
#   SSL certificate to be used by the influxdb service.  Defaults to the agent certificate issued by the Puppet CA for the local machine.
# @param ssl_key_file
#   Private key used in the CSR for the certificate specified by $ssl_cert_file.  Defaults to the private key of the local machine for generating a CSR for the Puppet CA
# @param ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.  Defaults to the Puppet CA.
# @param influxdb_host
#   fqdn of the host running InfluxDB.  Defaults to the fqdn of the local machine
# @param intial_org
#   Name of the initial organization to use during initial setup.  Defaults to puppetlabs
# @param intial_bucket
#   Name of the initial bucket to use during initial setup.  Defaults to puppet_data
# @param admin_user
#   Name of the administrative user to use during initial setup.  Defaults to admin
# @param admin_pass
#   Password for the administrative user in Sensitive format used during initial setup.  Defaults to puppetlabs
# @param token_file
#   File on disk containing an administrative token.  This class will write the token generated as part of initial setup to this file.  Note that functions or anything run in Puppet server will not be able to use this file, so setting $token after initial setup is recommended.
class influxdb::install(
  Boolean $manage_repo = true,
  Boolean $manage_setup = true,
  Boolean $manage_initial_resources = true,
  Boolean $manage_telegraf_token = true,

  String  $repo_name = 'influxdb2',
  String  $version = '2.1.1',
  String  $archive_source = 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.1.1-linux-amd64.tar.gz',

  Boolean $use_ssl = $influxdb::use_ssl,
  Boolean $manage_ssl = true,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',

  String  $influxdb_host = $influxdb::influxdb_host,
  String  $initial_org = 'puppetlabs',
  String  $initial_bucket = 'puppet_data',

  String  $admin_user = 'admin',
  Sensitive[String[1]] $admin_pass = Sensitive('puppetlabs'),
  String  $token_file = $influxdb::token_file,

) inherits influxdb {

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
    fail("Unable to manage InfluxDB installation on host ${facts['fqdn']}")
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
        yumrepo {$repo_name:
          ensure   => 'present',
          name     => $repo_name,
          baseurl  => "https://repos.influxdata.com/${dist}/\$releasever/\$basearch/stable",
          gpgkey   => 'https://repos.influxdata.com/influxdb2.key https://repos.influxdata.com/influxdb.key',
          enabled  => '1',
          gpgcheck => '1',
          target   => '/etc/yum.repos.d/influxdb2.repo',
        }
      }
    }
    package {'influxdb2':
      ensure  => $version,
      require => Yumrepo[$repo_name],
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
      ensure   => present,
      content  => epp('influxdb/influxdb_service.epp',
      env_file => "${base_dir}/influxdb2"),
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
      mode   => '0775',
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
    if $manage_ssl {
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
    }

    file {'/etc/systemd/system/influxdb.service.d':
      ensure => directory,
      owner  => 'influxdb',
      notify => Service['influxdb'],
    }
    file {'/etc/systemd/system/influxdb.service.d/override.conf':
      ensure  => file,
      #TODO: epp necessary?
      content => epp(
        'influxdb/influxdb_dropin.epp',
        {
          cert => '/etc/influxdb/cert.pem',
          key  => '/etc/influxdb/key.pem',
        }
      ),
      notify  => Service['influxdb'],
    }
  }

  service {'influxdb':
    ensure => running,
    enable => true,
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
      influxdb_auth {'puppet telegraf token':
        ensure      => present,
        org         => $initial_org,
        permissions => [
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'telegrafs'
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'telegrafs'
            }
          },
          {
            'action'   => 'read',
            'resource' => {
              'type'   => 'buckets'
            }
          },
          {
            'action'   => 'write',
            'resource' => {
              'type'   => 'buckets'
            }
          },
        ],
        require     => Service['influxdb'],
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
        labels  => ['puppetlabs/influxdb'],
        require => [Influxdb_setup[$influxdb_host], Influxdb_label['puppetlabs/influxdb']],
      }

      influxdb_org {$initial_org:
        ensure  => present,
        require => [Influxdb_setup[$influxdb_host], Influxdb_label['puppetlabs/influxdb']],
      }
    }
  }
}
