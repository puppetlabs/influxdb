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
#   URL containing an InfluxDB archive if not installing from a repository or false to disable installing from source.
#   Defaults to version 2.6.1 on amd64 architechture.
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
# @param port
#   port of the InfluxDB Service. Defaults to 8086
# @param initial_org
#   Name of the initial organization to use during initial setup.  Defaults to puppetlabs
# @param initial_bucket
#   Name of the initial bucket to use during initial setup.  Defaults to puppet_data
# @param admin_user
#   Name of the administrative user to use during initial setup.  Defaults to admin
# @param admin_pass
#   Password for the administrative user in Sensitive format used during initial setup.  Defaults to puppetlabs
# @param token_file
#   File on disk containing an administrative token.  This class will write the token generated as part of initial setup to this file.
#   Note that functions or code run in Puppet server will not be able to use this file, so setting $token after setup is recommended.
# @param repo_gpg_key_id
#   ID of the GPG signing key
# @param repo_url 
#   URL of the Package repository
# @param repo_gpg_key_url
#   URL of the GPG signing key
class influxdb (
  # Provided by module data
  String  $host,
  Stdlib::Port::Unprivileged $port,
  String  $initial_org,
  String  $initial_bucket,
  String  $repo_gpg_key_id,
  String  $repo_gpg_key_url,
  Boolean $manage_repo,

  Boolean $manage_setup = true,

  Optional[String] $repo_url = undef,
  String  $repo_name = 'influxdb2',
  String  $version = '2.6.1',
  Variant[String,Boolean[false]] $archive_source = 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.6.1-linux-amd64.tar.gz',

  Boolean $use_ssl = true,
  Boolean $manage_ssl = true,
  String  $ssl_cert_file = "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
  String  $ssl_key_file ="/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
  String  $ssl_ca_file ='/etc/puppetlabs/puppet/ssl/certs/ca.pem',

  String  $admin_user = 'admin',
  Sensitive[String[1]] $admin_pass = Sensitive('puppetlabs'),
  String  $token_file = $facts['identity']['user'] ? {
    'root'  => '/root/.influxdb_token',
    default => "/home/${facts['identity']['user']}/.influxdb_token" #lint:ignore:parameter_documentation
  },
) {
  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  unless $host == $facts['networking']['fqdn'] or $host == $facts['networking']['hostname'] or $host == 'localhost' {
    fail(
      @("MSG")
        Unable to manage InfluxDB installation on host: ${host}.
        Management of repos, packages and services etc is only possible on the local host (${facts['networking']['fqdn']}).
      | MSG
    )
  }

  # If managing SSL, install the package before managing files under /etc/influxdb in order to ensure the directory exists
  $package_before = if $use_ssl and $manage_ssl {
    [
      File['/etc/influxdb/cert.pem', '/etc/influxdb/key.pem', '/etc/influxdb/ca.pem', '/etc/systemd/system/influxdb.service.d'],
      Service['influxdb']
    ]
  }
  else {
    Service['influxdb']
  }

  # If we are managing the repository, set it up and install the package with a require on the repo
  if $manage_repo {
    #TODO: other distros
    case $facts['os']['family'] {
      'RedHat': {
        yumrepo { $repo_name:
          ensure   => 'present',
          descr    => $repo_name,
          name     => $repo_name,
          baseurl  => $repo_url,
          gpgkey   => $repo_gpg_key_url,
          enabled  => '1',
          gpgcheck => '1',
          target   => '/etc/yum.repos.d/influxdb2.repo',
        }
        $package_require = Yumrepo[$repo_name]
      }
      'Debian': {
        include apt
        apt::source { $repo_name:
          ensure   => 'present',
          comment  => 'The InfluxDB2 repository',
          location => $repo_url,
          release  => 'stable',
          repos    => 'main',
          key      => {
            'id'     => $repo_gpg_key_id,
            'source' => $repo_gpg_key_url,
          },
        }
        $package_require = [
          Apt::Source[$repo_name],
          Class['Apt::Update']
        ]
      }
      default: {
        notify { 'influxdb_repo_warn':
          message  => "Unable to manage repo on ${facts['os']['family']}, using archive source",
          loglevel => 'warn',
        }
      }
    }

    package { 'influxdb2':
      ensure  => $version,
      require => $package_require,
      before  => $package_before,
    }
  }
  # If not managing the repo, install the package from archive source
  elsif $archive_source {
    file { ['/etc/influxdb', '/opt/influxdb', '/etc/influxdb/scripts']:
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
    file { '/etc/systemd/system/influxdb.service':
      ensure   => file,
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
      before          => Service['influxdb'],
    }

    group { 'influxdb':
      ensure => present,
    }
    user { 'influxdb':
      ensure => present,
      gid    => 'influxdb',
    }

    file { '/etc/influxdb/scripts/influxd-systemd-start.sh':
      ensure => file,
      source => 'puppet:///modules/influxdb/influxd-systemd-start.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0775',
      notify => Service['influxdb'],
    }
  }

  # Otherwise, assume we have a source for the package
  else {
    package { 'influxdb2':
      ensure => installed,
      before => $package_before,
    }
  }

  service { 'influxdb':
    ensure => running,
    enable => true,
  }

  if $use_ssl {
    if $manage_ssl {
      file { '/etc/influxdb/cert.pem':
        ensure => file,
        source => "file:///${ssl_cert_file}",
        notify => Service['influxdb'],
      }
      file { '/etc/influxdb/key.pem':
        ensure => file,
        source => "file:///${ssl_key_file}",
        notify => Service['influxdb'],
      }
      file { '/etc/influxdb/ca.pem':
        ensure => file,
        source => "file:///${ssl_ca_file}",
        notify => Service['influxdb'],
      }
    }

    file { '/etc/systemd/system/influxdb.service.d':
      ensure => directory,
      owner  => 'influxdb',
      notify => Service['influxdb'],
    }
    file { '/etc/systemd/system/influxdb.service.d/override.conf':
      ensure  => file,
      #TODO: epp necessary?
      content => epp(
        'influxdb/influxdb_dropin.epp',
        {
          cert => '/etc/influxdb/cert.pem',
          key  => '/etc/influxdb/key.pem',
          port => $port,
        }
      ),
      notify  => Service['influxdb'],
    }
  }

  if $manage_setup {
    influxdb_setup { $host:
      ensure     => 'present',
      port       => $port,
      use_ssl    => $use_ssl,
      token_file => $token_file,
      bucket     => $initial_bucket,
      org        => $initial_org,
      username   => $admin_user,
      password   => $admin_pass,
      require    => Service['influxdb'],
    }
  }
}
