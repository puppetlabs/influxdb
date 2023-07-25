require 'uri'
require 'json'

Puppet::Functions.create_function(:'influxdb::retrieve_token') do
  dispatch :retrieve_token_file do
    param 'String', :uri
    param 'String', :token_name
    param 'String', :admin_token_file
    param 'Boolean', :use_system_store
    optional_param 'String', :ca_bundle
  end

  dispatch :retrieve_token do
    param 'String', :uri
    param 'String', :token_name
    param 'Sensitive', :admin_token
    param 'Boolean', :use_system_store
    optional_param 'String', :ca_bundle
  end

  def retrieve_token_file(uri, token_name, admin_token_file, use_system_store, ca_bundle = '')
    admin_token = File.read(admin_token_file)
    retrieve_token(uri, token_name, admin_token, use_system_store, ca_bundle)
  rescue Errno::EISDIR, Errno::EACCES, Errno::ENOENT => e
    Puppet.err("Unable to retrieve #{token_name}": e.message)
    nil
  end

  def retrieve_token(uri, token_name, admin_token, use_system_store, ca_bundle = '')
    if admin_token.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
      admin_token = admin_token.unwrap
    end

    client = Puppet.runtime[:http]
    # If using the system store, configure an OpenSSL::X509::Store object to add to the ssl context
    if use_system_store
      # Throw an error if a non-existent CA bundle was provided
      if !ca_bundle.empty? && !File.file?(ca_bundle)
        Puppet.err("No CA bundle found at #{ca_bundle}")
        nil
      end
    end

    response = if use_system_store
                 cert_store = OpenSSL::X509::Store.new
                 # Add the CA bundle to the store object if provided
                 if !ca_bundle.empty?
                   cert_store.add_file(ca_bundle)
                 else
                   # Otherwise use the default system path
                   cert_store.set_default_paths
                 end

                 ssl_context = Puppet::SSL::SSLContext.new(
                   verify_peer: false,
                   store: cert_store,
                 )

                 client_options = { ssl_context: ssl_context }
                 client.get(URI(uri + '/api/v2/authorizations'),
                                        headers: { 'Authorization' => "Token #{admin_token}" }, options: client_options)
               else
                 client.get(URI(uri + '/api/v2/authorizations'),
                                        headers: { 'Authorization' => "Token #{admin_token}" })
               end

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
