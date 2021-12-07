define influxdb::telegraf::agent (
  String $service_name = $title,
  String $config_file = '/etc/telegraf/telegraf.conf',
  String $config_dir = '/etc/telegraf/telegraf.d',
  #TODO
  Optional[Sensitive[String[1]]] $token = undef,
){
  file {"/etc/systemd/system/${service_name}.service.d":
    ensure => directory,
    owner  => 'telegraf',
    group  => 'telegraf',
    mode   => '700',
  }
  #TODO: for now, place a token in this file with the content
  # [Service]
  # Environment="INFLUX_TOKEN=<token>"
  file {"/etc/systemd/system/${service_name}.service.d/override.conf":
    ensure  => file,
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
    subscribe => File["/etc/systemd/system/${service_name}.service"],
  }
}
