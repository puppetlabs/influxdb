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
  rescue StandardError => e
    context.err("Error canonicalizing resources: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def get(context)
    init_auth if @auth.empty?
    get_org_info if @org_hash.empty?
    get_bucket_info if @bucket_hash.empty?
    get_label_info if @label_hash.empty?
    get_dbrp_info if @dbrp_hash.empty?
    get_user_info if @user_map.empty?

    response = influx_get('/api/v2/buckets')
    ret = []
    response.each do |r|
      next unless r['buckets']
      r['buckets'].select { |bucket| bucket['type'] == 'user' }.each do |bucket|
        dbrp = @dbrp_hash.find { |d| d['bucketID'] == bucket['id'] }

        links_hash = @bucket_hash.find { |b| b['name'] == bucket['name'] }
        bucket_members = links_hash.dig('members', 0, 'users')
        bucket_labels = links_hash.dig('labels', 0, 'labels')

        ret << {
          name: bucket['name'],
          ensure: 'present',
          use_ssl: @use_ssl,
          host: @host,
          port: @port,
          token: @token,
          token_file: @token_file,
          org: name_from_id(@org_hash, bucket['orgID']),
          retention_rules: bucket['retentionRules'],
          members: bucket_members ? bucket_members.map { |member| member['name'] } : [],
          labels: bucket_labels ? bucket_labels.map { |label| label['name'] } : [],
          create_dbrp: dbrp ? true : false,
        }
      end
    end

    ret
  rescue StandardError => e
    context.err("Error getting bucket state: #{e.message}")
    context.err(e.backtrace)
    nil
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
  rescue StandardError => e
    context.err("Error creating bucket: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def update(context, name, should)
    context.debug("Updating '#{name}' with #{should.inspect}")
    bucket_id = id_from_name(@bucket_hash, name)

    should_members = should[:members] ? should[:members] : []
    should_labels = should[:labels] ? should[:labels] : []

    bucket_members = @bucket_hash.find { |bucket| bucket['name'] == name }.dig('members', 0, 'users')
    bucket_members = bucket_members ? bucket_members.map { |user| user['name'] } : []
    bucket_labels = @bucket_hash.find { |bucket| bucket['name'] == name }.dig('labels', 0, 'labels')

    users_to_remove = bucket_members - should_members
    users_to_add = should_members - bucket_members

    users_to_remove.each do |user|
      user_id = id_from_name(@user_map, user)
      if user_id
        influx_delete("/api/v2/buckets/#{bucket_id}/members/#{user_id}")
      else
        context.warning("Could not find user #{user}")
      end
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
      if label_id
        influx_delete("/api/v2/buckets/#{bucket_id}/labels/#{label_id}")
      else
        context.warning("Could not find label #{label}")
      end
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
  rescue StandardError => e
    context.err("Error updating buckets: #{e.message}")
    context.err(e.backtrace)
    nil
  end

  def delete(context, name)
    context.debug("Deleting '#{name}'")
    id = id_from_name(@bucket_hash, name)
    influx_delete("/api/v2/buckets/#{id}")
  rescue StandardError => e
    context.err("Error deleting bucket: #{e.message}")
    context.err(e.backtrace)
    nil
  end
rescue StandardError => e
  context.err("Error deleting bucket state: #{e.message}")
  context.err(e.backtrace)
  nil
end
