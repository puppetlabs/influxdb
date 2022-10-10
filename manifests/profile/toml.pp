# @summary Installs the toml-rb gem inside Puppet server
#
# @param version
#   Specific version of toml-rb gem
#
# @example Basic usage
#   include influxdb::profile::toml
#

#
class influxdb::profile::toml (
  String $version,
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
}
