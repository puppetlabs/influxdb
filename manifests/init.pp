# @summary Installs, configures, and performs initial setup of InfluxDB 2.x
# @example Basic usage
#   include influxdb
#
#   class {'influxdb':
#     initial_org => 'my_org',
#     initial_bucket => 'my_bucket',
#   }
# @param manage_repo
#   Whether to manage a repository to provide InfluxDB packages.  Defaults to true
# @param manage_setup
#   Whether to perform initial setup of InfluxDB.  This will create an initial organization, bucket, and admin token.  Defaults to true.
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
#   Private key used in the CSR for the certificate specified by $ssl_cert_file.
#   Defaults to the private key of the local machine for generating a CSR for the Puppet CA
# @param ssl_ca_file
#   CA certificate issued by the CA which signed the certificate specified by $ssl_cert_file.  Defaults to the Puppet CA.
# @param host
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
#   File on disk containing an administrative token.  This class will write the token generated as part of initial setup to this file.
#   Note that functions or code run in Puppet server will not be able to use this file, so setting $token after setup is recommended.
class influxdb(
  # Provided by module data
  String  $host,
  Integer $port,
  String  $initial_org,
  String  $initial_bucket,

  Boolean $manage_repo = true,
  Boolean $manage_setup = true,

  String  $repo_name = 'influxdb2',
  String  $version = '2.1.1',
  String  $archive_source = 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.1.1-linux-amd64.tar.gz',

  Boolean $use_ssl = true,
  Boolean $manage_ssl = true,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',

  String  $admin_user = 'admin',
  Sensitive[String[1]] $admin_pass = Sensitive('puppetlabs'),
  String  $token_file = $facts['identity']['user'] ? {
                                      'root'  => '/root/.influxdb_token',
                                      default => "/home/${facts['identity']['user']}/.influxdb_token"
                                    },

){

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  unless $host == $facts['fqdn'] or $host == 'localhost' {
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
          descr    => $repo_name,
          name     => $repo_name,
          baseurl  => "https://repos.influxdata.com/${dist}/\$releasever/\$basearch/stable",
          gpgkey   => 'https://repos.influxdata.com/influxdb2.key https://repos.influxdata.com/influxdb.key',
          enabled  => '1',
          gpgcheck => '1',
          target   => '/etc/yum.repos.d/influxdb2.repo',
        }
      }
      default: {
        notify {'influxdb_repo_warn':
          message  => "Unable to manage repo on ${facts['os']['family']}, using archive source",
          loglevel => 'warn',
        }
      }
    }

    package {'influxdb2':
      ensure  => $version,
      require => Yumrepo[$repo_name],
    }

    service {'influxdb':
      ensure  => running,
      enable  => true,
      require => Package['influxdb2'],
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
      env_file => "${default_dir}/influxdb2"),
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

    service {'influxdb':
      ensure  => running,
      enable  => true,
      require => File['/opt/influxdb'],
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

  if $manage_setup {
    influxdb_setup {$host:
      ensure     => 'present',
      token_file => $token_file,
      bucket     => $initial_bucket,
      org        => $initial_org,
      username   => $admin_user,
      password   => $admin_pass,
      require    => Service['influxdb'],
    }

  }
}
