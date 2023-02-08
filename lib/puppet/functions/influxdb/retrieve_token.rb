require 'uri'
require 'json'

Puppet::Functions.create_function(:'influxdb::retrieve_token') do
  dispatch :retrieve_token_file do
    param 'String', :uri
    param 'String', :token_name
    param 'String', :admin_token_file
  end

  dispatch :retrieve_token do
    param 'String', :uri
    param 'String', :token_name
    param 'Sensitive', :admin_token
  end

  def retrieve_token_file(uri, token_name, admin_token_file)
    admin_token = File.read(admin_token_file)
    retrieve_token(uri, token_name, admin_token)
  rescue Errno::EISDIR, Errno::EACCESS, Errno::ENOENT => e
    Puppet.err("Unable to retrieve #{token_name}": e.message)
    nil
  end

  def retrieve_token(uri, token_name, admin_token)
    if admin_token.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
      admin_token = admin_token.unwrap
    end

    client = Puppet.runtime[:http]
    response = client.get(URI(uri + '/api/v2/authorizations'),
                           headers: { 'Authorization' => "Token #{admin_token}" })

    if response.success?
      body = JSON.parse(response.body)
      token = body['authorizations'].find { |auth| auth['description'] == token_name }
      token ? token['token'] : nil
    else
      Puppet.err("Unable to retrieve #{token_name}": response.body)
      nil
    end
  rescue StandardError => e
    Puppet.err("Unable to retrieve #{token_name}": e.message)
    nil
  end
end
