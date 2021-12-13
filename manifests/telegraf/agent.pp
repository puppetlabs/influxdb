define influxdb::telegraf::agent (
  String $service_name = $title,
  String $config_file = '/etc/telegraf/telegraf.conf',
  String $config_dir = '/etc/telegraf/telegraf.d',
  #TODO
  Sensitive[String[1]] $token = $influxdb::token,
){
  file {"/etc/systemd/system/${service_name}.service.d":
    ensure => directory,
    owner  => 'telegraf',
    group  => 'telegraf',
    mode   => '700',
  }
  file {"/etc/systemd/system/${service_name}.service.d/override.conf":
    ensure  => file,
    content => epp('influxdb/telegraf_environment_file.epp', { token => $token }),
  }

  file {"/etc/systemd/system/${service_name}.service":
    ensure  => present,
    content => epp('influxdb/telegraf_service.epp',
      { 'environment_file' => "/etc/systemd/system/${service_name}.service.d/override.conf",
        'config_file'   => $config_file,
        'config_dir'   => $config_dir,
      }
    )
  }

  service {"$service_name":
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/systemd/system/${service_name}.service", "/etc/systemd/system/${service_name}.service.d/override.conf"],
  }
}
