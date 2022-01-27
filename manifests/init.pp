# @summary Base dependency for all influxdb_* types and providers
# @example Basic usage
#   require influxdb
# @param influxdb_host
#   fqdn of the host running InfluxDB.  Defaults to the fqdn of the local machine
# @param influxdb_port
#   Port used by the influxdb service.  Defaults to 8086
# @param use_ssl
#   Whether to use http or https connections.  Defaults to true (https).
#   Configuration and management of the ssl bundle is provided by the influxdb::install class
# @param token
#   Administrative token in Sensitive format. This parameter takes precedence over $token_file if both are provided
# @param token_file
#   File on disk containing an administrative token.  The influxdb::install class will write the token generated as part of initial setup to this file.  Note that functions or anything run in Puppet server will not be able to use this file, so $token is preferred.
class influxdb(
  String  $influxdb_host = $facts['fqdn'],
  Integer $influxdb_port = 8086,
  Boolean $use_ssl = true,

  Optional[Sensitive[String[1]]] $token = undef,
  String  $token_file = $facts['identity']['user'] ? {
                                      'root'  => '/root/.influxdb_token',
                                      default => "/home/${facts['identity']['user']}/.influxdb_token"
                                    },
){
  # We have to instantiate the base type before other dependent resources to avoid autoloading issues
  # Classes that manage InfluxDB resources should use 'require influxdb' to satisfy this dependency
  influxdb {$influxdb_host:
    ensure        => present,
    influxdb_port => $influxdb_port,
    token         => $token,
    token_file    => $token_file,
    use_ssl       => $use_ssl,
  }
}
