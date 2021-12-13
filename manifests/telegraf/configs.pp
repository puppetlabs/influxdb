class influxdb::telegraf::configs (
  String $influxdb_repo_name = $influxdb::influxdb_repo_name,
  String $influxdb_host = $influxdb::influxdb_host,
  String  $telegraf_config_file = $influxdb::telegraf_config_file,
  String  $telegraf_config_dir = $influxdb::telegraf_config_file,
  # Set of default options for /etc/telegraf/telegraf.conf
  Hash   $agent_config = influxdb::from_toml(file('influxdb/telegraf_agent.conf')),
  # Default options for [[outputs.influxdb_v2]]
  Hash   $output_defaults = $influxdb::output_defaults,
  String $config_file = '/etc/telegraf/telegraf.conf',
  String $config_dir = '/etc/telegraf/telegraf.d',
  Boolean $include_system_metrics = true,
  # Whether to store Telegraf configs locally.
  Boolean $store_config = true,
  Boolean $manage_token = true,
  Optional[Array[Hash]] $configs = [],
  Sensitive[String[1]] $token,
){
  if $token {
    notify {"$token": }
  }
  exec { 'puppet_telegraf_daemon_reload':
    command     => 'systemctl daemon-reload',
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }


  if $include_system_metrics {
    $system_config = epp('influxdb/telegraf_system.epp',
      $output_defaults + {'urls' => ["'http://${influxdb_host}:8086'"]}
    ).influxdb::from_toml()
    $outputs = $system_config.dig('outputs', 'influxdb_v2', 0)

    telegraf_config {'puppet_system':
      ensure        => present,
      config        => $system_config,
      influxdb_host => $influxdb_host,
      org           => $outputs['organization'],
      metadata      => { 'buckets' => [$outputs['bucket']] },
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
