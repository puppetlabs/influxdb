Facter.add(:toml_rb_gem) do
  confine kernel: 'Linux'

  setcode do
    { gem_installed: File.directory?('/opt/puppetlabs/server/data/puppetserver/jruby-gems/gems/toml-rb-2.1.1/') }
  end
end
