require 'spec_helper_acceptance'

# Exercises the InfluxDB resource types (org, bucket, label, user, auth) end to
# end against a running instance. The module's initial setup writes an admin
# token to /root/.influxdb_token, which the resources pick up automatically when
# no explicit token is supplied. Verification is done by querying the InfluxDB
# 2.x HTTP API directly so we assert on real server state rather than the
# catalog. SSL is enabled by default (Puppet CA certs), so the API is queried
# over HTTPS with -k.
describe 'influxdb resource management' do
  # Query a path under /api/v2 using the admin token saved by the module.
  def influx_api(path)
    run_shell(%(curl -sk -H "Authorization: Token $(cat /root/.influxdb_token)" https://localhost:8086/api/v2/#{path})).stdout
  end

  context 'when creating resources' do
    pp = <<-MANIFEST
      include influxdb

      influxdb_org { 'acceptance_org':
        ensure      => present,
        description => 'Org created by acceptance tests',
      }

      influxdb_label { 'acceptance_label':
        ensure  => present,
        org     => 'acceptance_org',
        require => Influxdb_org['acceptance_org'],
      }

      influxdb_bucket { 'acceptance_bucket':
        ensure          => present,
        org             => 'acceptance_org',
        labels          => ['acceptance_label'],
        retention_rules => [{
          'type'                      => 'expire',
          'everySeconds'              => 2592000,
          'shardGroupDurationSeconds' => 604800,
        }],
        require         => Influxdb_org['acceptance_org'],
      }

      # NOTE: password is intentionally omitted. It is an init_only attribute
      # and the InfluxDB API never returns it, so setting it here makes every
      # subsequent apply non-idempotent (the type documents that passwords must
      # be set manually after creation).
      influxdb_user { 'acceptance_user':
        ensure => present,
      }

      influxdb_auth { 'acceptance read token':
        ensure      => present,
        org         => 'acceptance_org',
        permissions => [
          {
            'action'   => 'read',
            'resource' => { 'type' => 'buckets' },
          },
        ],
        require     => Influxdb_org['acceptance_org'],
      }
    MANIFEST

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    it 'creates the organization' do
      expect(influx_api('orgs')).to match(%r{acceptance_org})
    end

    it 'creates the bucket with its label' do
      buckets = influx_api('buckets')
      expect(buckets).to match(%r{acceptance_bucket})
      expect(influx_api('labels')).to match(%r{acceptance_label})
    end

    it 'creates the user' do
      expect(influx_api('users')).to match(%r{acceptance_user})
    end

    it 'creates the authorization token' do
      expect(influx_api('authorizations')).to match(%r{acceptance read token})
    end
  end

  context 'when removing resources' do
    pp = <<-MANIFEST
      include influxdb

      influxdb_auth { 'acceptance read token':
        ensure      => absent,
        org         => 'acceptance_org',
        permissions => [
          { 'action' => 'read', 'resource' => { 'type' => 'buckets' } },
        ],
      }

      influxdb_bucket { 'acceptance_bucket':
        ensure => absent,
        org    => 'acceptance_org',
      }

      influxdb_label { 'acceptance_label':
        ensure => absent,
        org    => 'acceptance_org',
      }

      influxdb_user { 'acceptance_user':
        ensure => absent,
      }

      influxdb_org { 'acceptance_org':
        ensure => absent,
      }
    MANIFEST

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    it 'removes the bucket' do
      expect(influx_api('buckets')).not_to match(%r{acceptance_bucket})
    end

    it 'removes the user' do
      expect(influx_api('users')).not_to match(%r{acceptance_user})
    end

    it 'removes the organization' do
      expect(influx_api('orgs')).not_to match(%r{acceptance_org})
    end
  end
end
