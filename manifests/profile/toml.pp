# @summary Installs the toml-rb gem inside Puppet server
# @example Basic usage
#   include influxdb::profile::toml
class influxdb::profile::toml (
  String $version = '2.1.1',
){
  $service_name = $facts['pe_server_version'] ? {
    undef   => 'puppetserver',
    default => 'pe-puppetserver',
  }

  package { 'toml-rb':
    ensure   => $version,
    provider => 'puppetserver_gem',
    notify   => Service[$service_name],
  }
}
