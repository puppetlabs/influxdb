define influxdb::telegraf::agent (
  String $service_name = $title,
  Sensitive[String[1]] $token,
  # Set of default options for /etc/telegraf/telegraf.conf
  Hash   $agent_defaults = influxdb::from_toml(file('influxdb/telegraf_agent.conf')),
  String $config_file = $influxdb::telegraf_config_file,
  String $config_dir = $influxdb::telegraf_config_dir,
){
  file {$config_file:
    ensure  => present,
    content => influxdb::to_toml($agent_defaults),
    notify  => Service[$service_name],
  }
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
