class influxdb(
  String  $influxdb_host = $facts['fqdn'],
  String  $influxdb_repo_name = 'influxdb2',
  String  $telegraf_config_file = '/etc/telegraf/telegraf.conf',
  String  $telegraf_config_dir = '/etc/telegraf/telegraf.d',
  Hash    $output_defaults = {'bucket' => 'puppet', 'organization' => 'puppetlabs', 'token' => '$INFLUX_TOKEN'},
  Boolean $manage_influxdb_setup = true,
  Boolean $manage_influxdb_repo = true,
  Boolean $manage_telegraf_service = true,
){
  # We have to instantiate the base type first to avoid autoloading issues
  influxdb {$influxdb_host: }

  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  if $manage_influxdb_setup {
    unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
      fail("Unable to manage InfluxDB on host ${influxdb_host}")
    }
    include influxdb::install
  }

  include influxdb::telegraf::configs

  if $manage_telegraf_service {
    influxdb::telegraf::agent {'puppet_telegraf':
      config_file => $telegraf_config_file,
      config_dir  => $telegraf_config_dir,
      notify      => Exec['puppet_telegraf_daemon_reload'],
    }
  }
}
