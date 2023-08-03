require 'uri'
require 'json'

Puppet::Functions.create_function(:'influxdb::retrieve_token') do
  dispatch :retrieve_token_file do
    param 'String', :uri
    param 'String', :token_name
    param 'String', :admin_token_file
    optional_param 'Boolean', :use_system_store
  end

  dispatch :retrieve_token do
    param 'String', :uri
    param 'String', :token_name
    param 'Sensitive', :admin_token
    optional_param 'Boolean', :use_system_store
  end

  def retrieve_token_file(uri, token_name, admin_token_file, use_system_store = false)
    admin_token = File.read(admin_token_file)
    retrieve_token(uri, token_name, admin_token, use_system_store)
  rescue Errno::EISDIR, Errno::EACCES, Errno::ENOENT => e
    Puppet.err("Unable to retrieve #{token_name}": e.message)
    nil
  end

  def retrieve_token(uri, token_name, admin_token, use_system_store = false)
    if admin_token.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
      admin_token = admin_token.unwrap
    end

    client = Puppet.runtime[:http]
    client_options = if use_system_store
                       { include_system_store: true }
                     else
                       {}
                     end

    response = client.get(URI(uri + '/api/v2/authorizations'),
                          headers: { 'Authorization' => "Token #{admin_token}", options: client_options })

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
