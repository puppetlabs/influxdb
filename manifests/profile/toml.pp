# @summary Installs the toml-rb gem inside Puppet server and agent
# @example Basic usage
#   include influxdb::profile::toml
# @param version
#   Version of the toml-rb gem to install
# @param install_options_server
#   Pass additional parameters to the puppetserver gem installation
# @param install_options_agent
#   Pass additional parameters to the puppetserver gem installation
class influxdb::profile::toml (
  String $version = '2.1.1',
  Array[String[1]] $install_options_server = [],
  Array[String[1]] $install_options_agent = [],
) {
  $service_name = $facts['pe_server_version'] ? {
    undef   => 'puppetserver',
    default => 'pe-puppetserver',
  }

  package { 'toml-rb':
    ensure          => $version,
    provider        => 'puppetserver_gem',
    install_options => $install_options_server,
    notify          => Service[$service_name],
  }

  package { 'toml-rb agent':
    ensure          => $version,
    name            => 'toml-rb',
    provider        => 'puppet_gem',
    install_options => $install_options_agent,
  }
}
