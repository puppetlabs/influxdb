# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/influxdb/influxdb'

# Implementation for performing initial setup of InfluxDB using the Resource API.
class Puppet::Provider::InfluxdbBucket::InfluxdbBucket < Puppet::ResourceApi::SimpleProvider
  include PuppetX::Puppetlabs::PuppetlabsInfluxdb
  def initialize
    @canonicalized_resources = []
    super
  end

  def canonicalize(_context, resources)
    init_attrs(resources)
    resources
  end

  def get(_context)
    init_auth
    get_org_info
    get_bucket_info
    get_label_info
    get_dbrp_info
    get_user_info

    response = influx_get('/api/v2/buckets', params: {})
    if response['buckets']
      response['buckets'].select { |bucket| bucket['type'] == 'user' }.reduce([]) do |memo, value|
        org_id = value['orgID']
        bucket_id = value['id']
        dbrp = influx_get("/api/v2/dbrps?orgID=#{org_id}", params: {})['content'].find do |d|
          d['bucketID'] == bucket_id
        end

        links_hash = @bucket_hash.find { |b| b['name'] == value['name'] }
        bucket_members = links_hash.dig('members', 'users')
        bucket_labels = links_hash.dig('labels', 'labels')

        memo + [
          {
            name: value['name'],
            ensure: 'present',
            org: name_from_id(@org_hash, value['orgID']),
            retention_rules: value['retentionRules'],
            members: bucket_members ? bucket_members.map { |member| member['name'] } : [],
            labels: bucket_labels ? bucket_labels.map { |label| label['name'] } : [],
            create_dbrp: dbrp ? true : false,
          },
        ]
      end
    else
      []
    end
  end

  def create(context, name, should)
    context.debug("Creating '#{name}' with #{should.inspect}")

    body = {
      name: should[:name],
      orgId: id_from_name(@org_hash, should[:org]),
      retentionRules: should[:retention_rules],
    }
    influx_post('/api/v2/buckets', JSON.dump(body))

    # Update this object's bucket cache to add the one we just created, and call update() if we need to create lables, members, or dbrps
    @bucket_hash = []
    get_bucket_info

    update(context, name, should) if should[:labels] || should[:members] || should[:create_dbrp]
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    bucket_id = id_from_name(@bucket_hash, name)

    should_members = should[:members] ? should[:members] : []
    should_labels = should[:labels] ? should[:labels] : []

    bucket_members = @bucket_hash.find { |bucket| bucket['name'] == name }.dig('members', 'users')
    bucket_members = bucket_members ? bucket_members.map { |user| user['name'] } : []
    bucket_labels = @bucket_hash.find { |bucket| bucket['name'] == name }.dig('labels', 'labels')

    users_to_remove = bucket_members - should_members
    users_to_add = should_members - bucket_members

    users_to_remove.each do |user|
      user_id = bucket_members.select { |u| u['name'] == user }.map { |u| u['id'] }.first
      influx_delete("/api/v2/buckets/#{bucket_id}/members/#{user_id}")
    end
    users_to_add.each do |user|
      user_id = id_from_name(@user_map, user)
      if user_id
        body = { id: user_id }
        influx_post("/api/v2/buckets/#{bucket_id}/members", JSON.dump(body))
      else
        context.warning("Could not find user #{user}")
      end
    end

    labels_to_remove = bucket_labels.map { |label| label['name'] } - should_labels
    labels_to_add = should_labels - bucket_labels.map { |label| label['name'] }

    labels_to_remove.each do |label|
      label_id = id_from_name(@label_hash, label)
      influx_delete("/api/v2/buckets/#{bucket_id}/labels/#{label_id}")
    end
    labels_to_add.each do |label|
      label_id = id_from_name(@label_hash, label)
      if label_id
        body = { 'labelID' => label_id }
        influx_post("/api/v2/buckets/#{bucket_id}/labels", JSON.dump(body))
      else
        context.warning("Could not find label #{label}")
      end
    end

    has_dbrp = @dbrp_hash.find { |dbrp| dbrp['database'] == name }
    if should[:create_dbrp] && !has_dbrp
      body = {
        bucketID: id_from_name(@bucket_hash, name),
        database: name,
        org: should[:org],
        retention_policy: 'Forever',
        default: true,
      }
      influx_post("/api/v2/dbrps?org=#{should[:org]}", JSON.dump(body))

    elsif !should[:create_dbrp] && has_dbrp
      influx_delete("/api/v2/dbrps/#{dbrp['id']}?orgID=#{dbrp['orgID']}")
    end

    body = {
      name: should[:name],
      retentionRules: should[:retention_rules],
    }
    influx_patch("/api/v2/buckets/#{bucket_id}", JSON.dump(body))
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")
    id = id_from_name(@bucket_hash, name)
    influx_delete("/api/v2/buckets/#{id}")
  end
end
