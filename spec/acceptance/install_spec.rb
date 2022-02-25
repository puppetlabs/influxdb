require 'spec_helper_acceptance'

describe 'influxdb class' do
  context 'init with default parameters' do
    it 'installs influxdb' do
      pp = <<-MANIFEST
        include influxdb::install
        MANIFEST

      idempotent_apply(pp)
    end

    # Influxdb should be listening on port 8086 by default
    describe port('8086') do
      it { is_expected.to be_listening }
    end
  end
end
