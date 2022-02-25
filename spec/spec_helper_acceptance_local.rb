# frozen_string_literal: true

require 'singleton'
require 'serverspec'
require 'puppetlabs_spec_helper/module_spec_helper'
include PuppetLitmus

RSpec.configure do |c|
  c.mock_with :rspec
  c.before :suite do
    # Ensure the metrics collector classes are applied
    pp = <<-PUPPETCODE
    include influxdb::install
    PUPPETCODE

    PuppetLitmus::PuppetHelpers.apply_manifest(pp)
  end
end
