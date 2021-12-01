define influxdb::telegraf::agent (
  String $service_name = $title,
  String $config_file = $influxdb::telegraf::telegraf::config_file,
  String $config_dir = $influxdb::telegraf::telegraf::config_dir,
  Boolean $store_token = true,
){
  $sysconfig_dir = $facts['os']['family'] ? {
    'RedHat' => '/etc/sysconfig',
    default  => '/etc/default',
  }

  file {"/etc/systemd/system/${service_name}.service":
    ensure  => present,
    content => epp('influxdb/telegraf_service.epp',
      { 'sysconfig_dir' => $sysconfig_dir,
        'config_file'   => $config_file,
        'config_dir'   => $config_dir,
      }
    )
  }

  service {"$service_name":
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/systemd/system/${service_name}.service"],
  }
}
