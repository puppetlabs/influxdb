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
