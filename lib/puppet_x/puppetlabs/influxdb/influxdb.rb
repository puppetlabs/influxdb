require 'puppet/http'
require 'json'
require 'uri'

# rubocop:disable Style/ClassAndModuleChildren
module PuppetX
  module Puppetlabs
    # Mixin module to provide constants and instance methods for the providers
    module PuppetlabsInfluxdb
      class << self
        attr_accessor :host, :port, :token_file, :use_ssl
      end

      self.host = Facter.value('fqdn')
      self.port = 8086
      self.use_ssl = true
      self.token_file = if Facter.value('identity')['user'] == 'root'
                          '/root/.influxdb_token'
                        else
                          "/home/#{Facter.value('identity')['user']}/.influxdb_token"
                        end

      attr_accessor :telegraf_hash, :user_map, :label_hash, :auth, :bucket_hash, :dbrp_hash

      def initialize
        @client ||= Puppet.runtime[:http]
        @org_hash = []
        @telegraf_hash = []
        @label_hash = []
        @user_map = []
        @bucket_hash = []
        @dbrp_hash = []
        @auth = {}
        @self_hash = []
      end

      # Make class instance variables available as instance variables to whichever object calls this method
      # For subclasses which call super, the instance variables will be part of their scope
      def init_attrs(resources)
        # TODO: Only one uri per resource type
        resources.each do |resource|
          @host ||= resource[:host] ? resource[:host] : PuppetlabsInfluxdb.host
          @port ||= resource[:port] ? resource[:port] : PuppetlabsInfluxdb.port
          @use_ssl ||= (!resource[:use_ssl].nil?) ? resource[:use_ssl] : PuppetlabsInfluxdb.use_ssl
          @token ||= resource[:token]
          @token_file ||= resource[:token_file] ? resource[:token_file] : PuppetlabsInfluxdb.token_file
        end

        protocol = @use_ssl ? 'https' : 'http'
        @influxdb_uri = "#{protocol}://#{@host}:#{@port}"
      end

      def init_auth
        @auth = if @token
                  { Authorization: "Token #{@token.unwrap}" }
                elsif @token_file && File.file?(@token_file)
                  token = File.read(@token_file)
                  { Authorization: "Token #{token}" }
                else
                  {}
                end
      end

      # Helper methods to map names to internal IDs
      def id_from_name(hashes, name)
        hashes.select { |user| user['name'] == name }.map { |user| user['id'] }.first
      end

      def name_from_id(hashes, id)
        hashes.select { |user| user['id'] == id }.map { |user| user['name'] }.first
      end

      # Helper function to process paginated responses.  Returns an array of responses
      def influx_get(name, results = [])
        # Return the current data if there is no 'next' object
        return results if name.nil?

        response = @client.get(URI(@influxdb_uri + name), headers: @auth)
        if response.success?
          # Recursively append the results of calling the URL in the 'next' object to our array
          body = JSON.parse(response.body)
          results << body
          influx_get(body.dig('links', 'next'), results)
        # We may receive a 404 if the api path doesn't exists, such as a /links request for an org with no labels
        # We won't consider this a fatal error
        elsif response.code == 404
          results
        else
          raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}"
        end
      rescue StandardError => e
        Puppet.err("Error in get call: #{e.message}")
        Puppet.err(e.backtrace)
        []
      end

      # def influx_get(name)
      #  _influx_get(name)
      # end

      def influx_post(name, body)
        response = @client.post(URI(@influxdb_uri + name), body, headers: @auth.merge({ 'Content-Type' => 'application/json' }))
        raise Puppet::DevError, "Received HTTP code '#{response.code}' with message '#{response.reason}'" unless response.success?

        JSON.parse(response.body ? response.body : '{}')
      end

      def influx_put(name, body)
        response = @client.put(URI(@influxdb_uri + name), body, headers: @auth.merge({ 'Content-Type' => 'application/json' }))
        raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}" unless response.success?

        JSON.parse(response.body ? response.body : '{}')
      end

      # Our HTTP class doesn't have a patch method, so we create the connection and use Net::HTTP manually
      def influx_patch(name, body)
        @client.connect(URI(@influxdb_uri)) do |conn|
          request = Net::HTTP::Patch.new(@influxdb_uri + name)
          request['Content-Type'] = 'application/json'

          request['Authorization'] = @auth[:Authorization]

          request.body = body
          response = conn.request(request)
          raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}" unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body ? response.body : '{}')
        end
      end

      def influx_delete(name)
        response = @client.delete(URI(@influxdb_uri + name), headers: @auth)
        raise Puppet::DevError, "Received HTTP code #{response.code} with message #{response.reason}" unless response.success?

        JSON.parse(response.body ? response.body : '{}')
      end

      def influx_setup
        response = influx_get('/api/v2/setup')
        response['allowed'] == false
      rescue StandardException
        false
      end

      def get_org_info
        response = influx_get('/api/v2/orgs')

        response.each do |r|
          next unless r['orgs']
          r['orgs'].each do |org|
            process_links(org, org['links'])
            @org_hash << org
          end
        end
      rescue StandardError => e
        Puppet.err("Error getting org state: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end

      def get_bucket_info
        response = influx_get('/api/v2/buckets')
        response.each do |r|
          next unless r['buckets']
          r['buckets'].each do |bucket|
            process_links(bucket, bucket['links'])
            @bucket_hash << bucket
          end
        end
      rescue StandardError => e
        Puppet.err("Error getting bucket state: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end

      def get_dbrp_info
        # org is a mandatory parameter, so we have to look over each org to get all dbrps
        # get_org_info must be called before this
        orgs = @org_hash.map { |org| org['id'] }
        orgs.each do |org|
          dbrp_response = influx_get("/api/v2/dbrps?orgID=#{org}")
          dbrp_response.each do |r|
            next unless r['content']
            r['content'].each do |dbrp|
              @dbrp_hash << dbrp.merge('name' => dbrp['database'])
            end
          end
        end
      rescue StandardError => e
        Puppet.err("Error getting dbrp state: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end

      def get_user_info
        response = influx_get('/api/v2/users')
        response.each do |r|
          next unless r['users']
          r['users'].each do |user|
            process_links(user, user['links'])
            @user_map << user
          end
        end
      rescue StandardError => e
        Puppet.err("Error getting user state: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end

      # No links entries for labels other than self
      def get_label_info
        response = influx_get('/api/v2/labels')
        response.each do |r|
          next unless r['labels']
          r['labels'].each do |label|
            @label_hash << label
          end
        end
      rescue StandardError => e
        Puppet.err("Error getting label state: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end

      def process_links(hash, links)
        # For each org hash returned by the api, traverse the 'links' entries and add an element to the hash
        # For example, given an org 'puppetlabs' with {"links" => ["buckets": "/api/v2/buckets?org=puppetlabs"]}
        #   add the results of the "buckets" api call to a "buckets" key
        links.each do |k, v|
          next if (k == 'self') || (k == 'write')
          hash[k] = influx_get(v)
        end
      rescue StandardError => e
        Puppet.err("Error processing links: #{e.message}")
        Puppet.err(e.backtrace)
        nil
      end
    end
  end
end
