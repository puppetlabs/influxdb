class influxdb(
  # namevar
  String $influxdb_host,
  Boolean $manage_influxdb_setup = true,
  Boolean $manage_influxdb_repo = true,
  String $ensure = 'present',
){
  # We can only manage repos, packages, services, etc on the node we are compiling a catalog for
  if $manage_influxdb_setup {
    unless $influxdb_host == $facts['fqdn'] or $influxdb_host == 'localhost' {
      fail("Unable to manage InfluxDB on host ${influxdb_host}")
    }
    include influxdb::install
  }
}
