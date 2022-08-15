require 'spec_helper_acceptance'

describe 'influxdb class' do
  context 'init with default parameters' do
    it 'installs influxdb' do
      pp = <<-MANIFEST
        include influxdb
      MANIFEST

      idempotent_apply(pp)
    end

    # Influxdb should be listening on port 8086 by default
    it 'is listening on port 8086' do
      expect(run_shell('ss -Htln sport = :8086').stdout).to match(%r{LISTEN})
    end
  end
end
