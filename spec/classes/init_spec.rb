require 'spec_helper'

describe 'influxdb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:baseurl_dir) do
        case os_facts[:os]['name']
        when 'RedHat'
          'rhel'
        when 'CentOS'
          'centos'
        when 'Ubuntu'
          'ubuntu'
        else
          case os_facts[:os]['family']
          when 'RedHat'
            'rhel'
          when 'Debian'
            'debian'
          end
        end
      end

      let(:package_version) do
        v = '2.6.1'
        return "#{v}-1" if os_facts[:os]['family'] == 'Debian'
        v
      end

      it { is_expected.to compile.with_all_deps }

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

          case os_facts[:os]['family']
          when 'Suse'
            is_expected.to contain_archive('/tmp/influxdb.tar.gz').with(
              ensure: 'present',
              extract: true,
              extract_command: 'tar xfz %s --strip-components=1',
              extract_path: '/opt/influxdb',
              creates: '/opt/influxdb/influxd',
              source: "https://dl.influxdata.com/influxdb/releases/influxdb2-#{package_version}-linux-amd64.tar.gz",
              cleanup: true,
            ).that_requires(
              [
                'File[/etc/influxdb]',
                'File[/opt/influxdb]',
              ],
            ).that_comes_before('Service[influxdb]')
          else
            is_expected.to contain_package('influxdb2').that_comes_before(
              [
                'File[/etc/influxdb/cert.pem]',
                'File[/etc/influxdb/key.pem]',
                'File[/etc/influxdb/ca.pem]',
                'File[/etc/systemd/system/influxdb.service.d]',
                'Service[influxdb]',
              ],
            ).with_ensure(package_version)
          end

          [
            '/etc/influxdb/cert.pem',
            '/etc/influxdb/ca.pem',
            '/etc/influxdb/key.pem',
          ].each do |file|
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

          [
            '/etc/systemd/system/influxdb.service.d',
            '/etc/systemd/system/influxdb.service.d/override.conf',
          ].each do |file|
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

        case os_facts[:os]['family']
        when 'RedHat'
          it {
            is_expected.to contain_yumrepo('influxdb2').with(
              ensure: 'present',
              descr: 'influxdb2',
              name: 'influxdb2',
              baseurl: "https://repos.influxdata.com/#{baseurl_dir}/$releasever/$basearch/stable",
              gpgkey: 'https://repos.influxdata.com/influxdata-archive_compat.key',
              enabled: '1',
              gpgcheck: '1',
              target: '/etc/yum.repos.d/influxdb2.repo',
            )

            is_expected.not_to contain_archive('/tmp/influxdb.tar.gz')
          }
        when 'Debian'
          it do
            is_expected.to contain_apt__source('influxdb2').with(
              ensure: 'present',
              location: "https://repos.influxdata.com/#{baseurl_dir}",
              release: 'stable',
              repos: 'main',
            )
          end
        end
      end

      context 'when using an archive source' do
        let(:params) { { host: 'localhost', manage_repo: false } }

        it {
          is_expected.not_to contain_yumrepo('influxdb2')

          [
            '/etc/influxdb',
            '/opt/influxdb',
            '/etc/influxdb/scripts',
          ].each do |file|
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
          ).that_requires(
            [
              'User[influxdb]',
              'Group[influxdb]',
            ],
          )

          [
            '/etc/influxdb/scripts/influxd-systemd-start.sh',
            '/etc/systemd/system/influxdb.service',
          ].each do |file|
            is_expected.to contain_file(file)
          end

          is_expected.to contain_user('influxdb')
          is_expected.to contain_group('influxdb')

          is_expected.to contain_archive('/tmp/influxdb.tar.gz').with(
            source: 'https://dl.influxdata.com/influxdb/releases/influxdb2-2.6.1-linux-amd64.tar.gz',
          ).that_requires(
            [
              'File[/etc/influxdb]',
              'File[/opt/influxdb]',
            ],
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

      context 'when using the system store' do
        let(:params) { { host: 'localhost', use_system_store: true } }

        it {
          is_expected.to contain_influxdb_setup('localhost').with(
            ensure: 'present',
            token_file: '/root/.influxdb_token',
            bucket: 'puppet_data',
            org: 'puppetlabs',
            username: 'admin',
            password: RSpec::Puppet::Sensitive.new('puppetlabs'),
            use_system_store: true,
          )
        }
      end
    end
  end
end
