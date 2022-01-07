# frozen_string_literal: true

require_relative '../influxdb/influxdb'
require 'puppet/resource_api/simple_provider'
require 'toml-rb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
# Inheriting from the base provider gives us the get() and put() methods, as
#   well as a class variable for the connection
class Puppet::Provider::TelegrafConfig::TelegrafConfig < Puppet::Provider::Influxdb::Influxdb
  def get(context)
    init_attrs()
    init_auth()
    get_org_info()
    get_telegraf_info()
    get_label_info()

    response = influx_get('/api/v2/telegrafs', params: {})
    if response['configurations']
      response['configurations'].reduce([]) { |memo, value|
        telegraf_labels = @telegraf_hash.find{ |label| label['name'] == value['name']}
        telegraf_labels = telegraf_labels ? telegraf_labels.dig('labels', 'labels') : []

        memo + [
          {
            name: value['name'],
            influxdb_host: @influxdb_host,
            org: name_from_id(@org_hash, value['orgID']),
            ensure: 'present',
            description: value['description'],
            config: TomlRB.parse(value['config']),
            metadata: value['metadata'],
            labels: telegraf_labels.map {|label| label['name']},
          }
        ]
      }
    else
      []
    end
  end

  def create(context, name, should)
    context.info("Creating '#{name}' with #{should.inspect}")

    #FIXME
    if should[:config] and should[:source]
      raise Puppet::DevError, "Recieved mutually exclusive parameters: 'config' and 'source'."
    end

    body = {
      name: should[:name],
      description: should[:description],
      config: TomlRB.dump(should[:config]),
      metadata: should[:metadata],
      orgID: id_from_name(@org_hash, should[:org])
    }
    response = influx_post('/api/v2/telegrafs', JSON.dump(body))

    update(context, name, should) if should[:labels]
  end

  def update(context, name, should)
    context.info("Updating '#{name}' with #{should.inspect}")

    get_telegraf_info()
    telegraf_id = id_from_name(@telegraf_hash, should[:name])
    links_hash = @telegraf_hash.find{ |telegraf| telegraf['name'] == name}

    telegraf_labels = links_hash ? links_hash.dig('labels', 'labels') : []
    should_labels = should[:labels] ? should[:labels] : []

    labels_to_remove = telegraf_labels.map{ |label| label['name']} - should_labels
    labels_to_add = should_labels - telegraf_labels.map{ |label| label['name']}

    labels_to_remove.each{ |label|
      label_id = id_from_name(@label_hash, label)
      influx_delete("/api/v2/telegrafs/#{telegraf_id}/labels/#{label_id}")
    }
    labels_to_add.each{ |label|
      label_id = id_from_name(@label_hash, label)
      if label_id
        body = { 'labelID' => label_id }
        influx_post("/api/v2/telegrafs/#{telegraf_id}/labels", JSON.dump(body))
      else
        context.warning("Could not find label #{label}")
      end
    }

    body = {
      name: should[:name],
      description: should[:description],
      config: TomlRB.dump(should[:config]),
      metadata: should[:metadata],
      orgID: id_from_name(@org_hash, should[:org])
    }
    influx_put("/api/v2/telegrafs/#{telegraf_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.info("Deleting '#{name}'")

    id = id_from_name(@telegraf_hash, name)
    influx_delete("/api/v2/telegrafs/#{id}")
  end

end
