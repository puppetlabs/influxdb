Facter.add(:toml_rb_gem) do
  confine kernel: 'Linux'

  setcode do
    { gem_installed: (Facter::Core::Execution.execute('/opt/puppetlabs/bin/puppetserver gem list toml-rb -i') == "true") }
  end
end
