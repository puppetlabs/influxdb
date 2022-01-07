class influxdb::telegraf::configs (
  String $influxdb_repo_name = $influxdb::influxdb_repo_name,
  String $influxdb_host = $influxdb::influxdb_host,
  String  $telegraf_config_file = $influxdb::telegraf_config_file,
  String  $telegraf_config_dir = $influxdb::telegraf_config_file,
  # Set of default options for /etc/telegraf/telegraf.conf
  Hash   $agent_defaults = influxdb::from_toml(file('influxdb/telegraf_agent.conf')),
  String $config_file = $influxdb::telegraf_config_file,
  String $config_dir = $influxdb::telegraf_config_dir,
  String $default_org = $influxdb::install::initial_org,
  String $default_bucket = $influxdb::install::initial_bucket,
  Boolean $use_ssl = $influxdb::use_ssl,
  String $ssl_cert_file = $influxdb::ssl_cert_file,
  String $ssl_key_file = $influxdb::ssl_key_file,
  String $ssl_ca_file = $influxdb::ssl_ca_file,
  Boolean $include_system_metrics = true,
  # Whether to store Telegraf configs locally.
  Boolean $store_config = true,
  Optional[Array[Hash]] $configs = [],
){
  exec { 'puppet_telegraf_daemon_reload':
    command     => 'systemctl daemon-reload',
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }

  $protocol = $use_ssl ? {
    true  => 'https',
    false => 'http',
  }


  file {$influxdb::telegraf_config_file:
    ensure  => present,
    content => influxdb::to_toml($agent_defaults),
  }

  if $include_system_metrics {
    $defaults = {
      'bucket'       => $default_bucket,
      'organization' => $default_org,
      'token'        => '$INFLUX_TOKEN',
      #FIXME
      'urls'         => ["'${protocol}://${influxdb_host}:8086'"],
    }

    $system_config = epp('influxdb/telegraf_system.epp', $defaults).influxdb::from_toml()

    telegraf_config {'puppet_system':
      ensure        => present,
      config        => $system_config,
      influxdb_host => $influxdb_host,
      org           => $defaults['organization'],
      metadata      => { 'buckets' => [$defaults['bucket']] },
      description   => 'System metrics from influxdb::telegraf::configs',
    }
    if $store_config {
      file {"${config_dir}/puppet_system.conf":
        ensure  => present,
        content => $system_config.influxdb::to_toml(),
      }
    }
  }

  #TODO: investigate --watch-config option for telegraf
  $configs.each |$config| {
    #TODO: dig() into the outputs hash to determine org and bucket
    telegraf_config {"${config['name']}":
      ensure => present,
      config => $config['config'],
      influxdb_host => $influxdb_host,
      org           => $config['org'],
      metadata      => { 'buckets' => $config['buckets']},
      #source        => URI('file:///etc/telegraf/telegraf.d/puppet_system.conf'),
      description   => "It's a me",
    }
    file {"${config_dir}/${config['name']}.conf":
      ensure  => present,
      content => $config['config'].influxdb::to_toml(),
    }
  }

}
