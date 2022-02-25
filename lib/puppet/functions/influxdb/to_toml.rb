require 'toml-rb'

Puppet::Functions.create_function(:'influxdb::to_toml') do
  dispatch :to_toml do
    param 'Hash', :hash
  end

  def to_toml(hash)
    TomlRB.dump(hash)
  end
end
