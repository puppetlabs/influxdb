require 'uri'
require 'json'

Puppet::Functions.create_function(:'influxdb::retrieve_token') do
  dispatch :retrieve_token do
    param 'String', :uri
    param 'Sensitive[String]', :admin_token
    param 'String', :token_name
  end

  def retrieve_token(uri, admin_token, token_name)
    client = Puppet.runtime[:http]
    response = client.get(URI(uri + '/api/v2/authorizations'),
                           headers: { 'Authorization' => "Token #{admin_token.unwrap}" })
    if response.success?
      body = JSON.load(response.body)
      token = body['authorizations'].find { |auth| auth['description'] == token_name }
      token['token'] ? token['token'] : nil
    else
      puts response.body
    end
  rescue Exception => e
    puts e.backtrace
  end
end
