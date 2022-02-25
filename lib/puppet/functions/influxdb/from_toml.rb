require 'toml-rb'

Puppet::Functions.create_function(:'influxdb::from_toml') do
  dispatch :from_toml do
    param 'String', :file
  end

  def from_toml(file)
    TomlRB.parse(file)
  end
end
