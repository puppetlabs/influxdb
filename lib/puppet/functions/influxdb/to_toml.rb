require 'toml-rb'

Puppet::Functions.create_function(:'influxdb::to_toml') do
  dispatch :to_toml do
    param 'Hash', :hash_or_array
  end
  dispatch :to_toml do
    param 'Array', :hash_or_array
  end

  def to_toml(hash_or_array)
    TomlRB.dump(hash_or_array)
  end
end

