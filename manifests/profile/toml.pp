# @summary Installs the toml-rb gem inside Puppet server and agent
# @example Basic usage
#   include influxdb::profile::toml
# @param version
#   Version of the toml-rb gem to install
class influxdb::profile::toml (
  String $version = '2.1.1',
) {
  $service_name = $facts['pe_server_version'] ? {
    undef   => 'puppetserver',
    default => 'pe-puppetserver',
  }

  package { 'toml-rb':
    ensure   => $version,
    provider => 'puppetserver_gem',
    notify   => Service[$service_name],
  }

  package { 'toml-rb agent':
    ensure   => $version,
    name     => 'toml-rb',
    provider => 'puppet_gem',
  }
}
