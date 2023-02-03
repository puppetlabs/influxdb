require 'spec_helper'
require 'pry'

describe 'influxdb' do
  let(:facts) { { os: { family: 'RedHat' }, identity: { user: 'root' } } }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end

  context 'when using default parameters' do
    let(:params) { { host: 'localhost' } }

    it {
      is_expected.to contain_class('influxdb').with(
        host: 'localhost',
        port: 8086,
        use_ssl: true,
        initial_org: 'puppetlabs',
        token: nil,
        token_file: '/root/.influxdb_token',
      )

      is_expected.to contain_service('influxdb').with_ensure('running')
      is_expected.to contain_package('influxdb2').that_comes_before([
                                                                      'File[/etc/influxdb/cert.pem]',
                                                                      'File[/etc/influxdb/key.pem]',
                                                                      'File[/etc/influxdb/ca.pem]',
                                                                      'File[/etc/systemd/system/influxdb.service.d]',
                                                                      'Service[influxdb]',
                                                                    ])
      is_expected.to contain_package('influxdb2').with_ensure('2.1.1')

      ['/etc/influxdb/cert.pem', '/etc/influxdb/ca.pem', '/etc/influxdb/key.pem'].each do |file|
        is_expected.to contain_file(file)
      end

      is_expected.to contain_influxdb_setup('localhost').with(
        ensure: 'present',
        token_file: '/root/.influxdb_token',
        bucket: 'puppet_data',
        org: 'puppetlabs',
        username: 'admin',
        password: RSpec::Puppet::Sensitive.new('puppetlabs'),
      )

      ['/etc/systemd/system/influxdb.service.d', '/etc/systemd/system/influxdb.service.d/override.conf'].each do |file|
        is_expected.to contain_file(file)
      end
    }
  end

  context 'when not using ssl' do
    let(:params) { { host: 'localhost', use_ssl: false } }

    it {
      is_expected.to contain_class('influxdb').with(use_ssl: false)

      is_expected.not_to contain_file('/etc/influxdb/cert.pem')
      is_expected.not_to contain_file('/etc/influxdb/ca.pem')
      is_expected.not_to contain_file('/etc/influxdb/key.pem')
    }
  end

  context 'when using a repository' do
    let(:params) { { host: 'localhost' } }

    it {
      is_expected.to contain_yumrepo('influxdb2').with(
          ensure: 'present',
          descr: 'influxdb2',
          name: 'influxdb2',
          baseurl: 'https://repos.influxdata.com/rhel/$releasever/$basearch/stable',
          gpgkey: 'https://repos.influxdata.com/influxdata-archive_compat.key',
          enabled: '1',
          gpgcheck: '1',
          target: '/etc/yum.repos.d/influxdb2.repo',
        )

      is_expected.not_to contain_archive('/tmp/influxdb.tar.gz')
    }
  end

  context 'when using an archive source' do
    let(:params) { { host: 'localhost', manage_repo: false } }

    it {
      is_expected.not_to contain_yumrepo('influxdb2')

      ['/etc/influxdb', '/opt/influxdb', '/etc/influxdb/scripts'].each do |file|
        is_expected.to contain_file(file).with(
          ensure: 'directory',
          owner: 'root',
          group: 'root',
        )
      end
      is_expected.to contain_file('/var/lib/influxdb').with(
        ensure: 'directory',
        owner: 'influxdb',
        group: 'influxdb',
      )
      is_expected.to contain_file('/var/lib/influxdb').that_requires(['User[influxdb]', 'Group[influxdb]'])

      ['/etc/influxdb/scripts/influxd-systemd-start.sh', '/etc/systemd/system/influxdb.service'].each do |file|
        is_expected.to contain_file(file)
      end

      is_expected.to contain_user('influxdb')
      is_expected.to contain_group('influxdb')

      is_expected.to contain_archive('/tmp/influxdb.tar.gz').with(
        source: 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.1.1-linux-amd64.tar.gz',
      )
      is_expected.to contain_archive('/tmp/influxdb.tar.gz').that_requires(
        ['File[/etc/influxdb]', 'File[/opt/influxdb]'],
      )
    }
  end

  context 'when not using a repo or archive source' do
    let(:params) { { host: 'localhost', manage_repo: false, archive_source: false } }

    it {
      is_expected.not_to contain_yumrepo('influxdb2')
      is_expected.not_to contain_archive('/tmp/influxdb.tar.gz')
    }
  end
end
