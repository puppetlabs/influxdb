# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.0.0](https://github.com/puppetlabs/influxdb/tree/v2.0.0) (2023-04-27)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.6.0...v2.0.0)

### Changed

- \(SUP-3952\) Remove Puppet 6 as a supported platform [\#78](https://github.com/puppetlabs/influxdb/pull/78) ([elainemccloskey](https://github.com/elainemccloskey))

### Added

- \(SUP-4195\) Puppet 8 release prep [\#79](https://github.com/puppetlabs/influxdb/pull/79) ([MartyEwings](https://github.com/MartyEwings))
- toml installation: Support `install_options` [\#77](https://github.com/puppetlabs/influxdb/pull/77) ([bastelfreak](https://github.com/bastelfreak))
- install toml-rb gem inside puppet agent [\#75](https://github.com/puppetlabs/influxdb/pull/75) ([vchepkov](https://github.com/vchepkov))

### Fixed

- \(SUP-3397\) Do not add/remove the admin user [\#74](https://github.com/puppetlabs/influxdb/pull/74) ([m0dular](https://github.com/m0dular))

## [v1.6.0](https://github.com/puppetlabs/influxdb/tree/v1.6.0) (2023-02-14)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.5.1...v1.6.0)

### Added

- Add default 90 day bucket retention [\#71](https://github.com/puppetlabs/influxdb/pull/71) ([m0dular](https://github.com/m0dular))

## [v1.5.1](https://github.com/puppetlabs/influxdb/tree/v1.5.1) (2023-02-09)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.5.0...v1.5.1)

### Fixed

- \(SUP-3968\) Support paginated api responses [\#65](https://github.com/puppetlabs/influxdb/pull/65) ([m0dular](https://github.com/m0dular))

## [v1.5.0](https://github.com/puppetlabs/influxdb/tree/v1.5.0) (2023-02-03)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.4.0...v1.5.0)

### Added

- GPG key changes [\#62](https://github.com/puppetlabs/influxdb/pull/62) ([m0dular](https://github.com/m0dular))
- Permit short hostnames to be used [\#60](https://github.com/puppetlabs/influxdb/pull/60) ([seanmil](https://github.com/seanmil))

### Fixed

- Update influxdb repo key [\#61](https://github.com/puppetlabs/influxdb/pull/61) ([elfranne](https://github.com/elfranne))

## [v1.4.0](https://github.com/puppetlabs/influxdb/tree/v1.4.0) (2022-11-07)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.3.1...v1.4.0)

### Added

- \(SUP-3704\) Customize influxdb port [\#56](https://github.com/puppetlabs/influxdb/pull/56) ([m0dular](https://github.com/m0dular))

## [v1.3.1](https://github.com/puppetlabs/influxdb/tree/v1.3.1) (2022-10-10)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.3.0...v1.3.1)

### Fixed

- \(SUP-3705\) Require Apt::Update class on Ubuntu [\#50](https://github.com/puppetlabs/influxdb/pull/50) ([m0dular](https://github.com/m0dular))

## [v1.3.0](https://github.com/puppetlabs/influxdb/tree/v1.3.0) (2022-10-07)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.2.1...v1.3.0)

### Added

- Helpful fail message for local host req on install [\#46](https://github.com/puppetlabs/influxdb/pull/46) ([zoojar](https://github.com/zoojar))

## [v1.2.1](https://github.com/puppetlabs/influxdb/tree/v1.2.1) (2022-09-29)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.2.0...v1.2.1)

### Fixed

- \(Sup 3678\) Fix use\_ssl parameter [\#42](https://github.com/puppetlabs/influxdb/pull/42) ([m0dular](https://github.com/m0dular))

## [v1.2.0](https://github.com/puppetlabs/influxdb/tree/v1.2.0) (2022-09-27)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.1.0...v1.2.0)

### Added

- Add support for installing from repository on Debian/Ubuntu [\#40](https://github.com/puppetlabs/influxdb/pull/40) ([m0dular](https://github.com/m0dular))
- add debian repo support [\#37](https://github.com/puppetlabs/influxdb/pull/37) ([SimonHoenscheid](https://github.com/SimonHoenscheid))
- Add options to set custom influxdb repo. [\#36](https://github.com/puppetlabs/influxdb/pull/36) ([SimonHoenscheid](https://github.com/SimonHoenscheid))

## [v1.1.0](https://github.com/puppetlabs/influxdb/tree/v1.1.0) (2022-08-17)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v1.0.0...v1.1.0)

### Added

- \(SUP-3557\) Add spec tests for the main class [\#32](https://github.com/puppetlabs/influxdb/pull/32) ([m0dular](https://github.com/m0dular))
- provide an option to disable installing from source [\#29](https://github.com/puppetlabs/influxdb/pull/29) ([vchepkov](https://github.com/vchepkov))

## [v1.0.0](https://github.com/puppetlabs/influxdb/tree/v1.0.0) (2022-05-02)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.3.0...v1.0.0)

### Changed

- Fix require on influxdb service [\#25](https://github.com/puppetlabs/influxdb/pull/25) ([m0dular](https://github.com/m0dular))

### Fixed

- Rescue exception in retrieve\_token function [\#24](https://github.com/puppetlabs/influxdb/pull/24) ([m0dular](https://github.com/m0dular))

## [v0.3.0](https://github.com/puppetlabs/influxdb/tree/v0.3.0) (2022-03-11)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.2.1...v0.3.0)

### Added

- Use token file on disk to fetch tokens [\#17](https://github.com/puppetlabs/influxdb/pull/17) ([m0dular](https://github.com/m0dular))

### Fixed

- Check if token file exists on disk [\#18](https://github.com/puppetlabs/influxdb/pull/18) ([m0dular](https://github.com/m0dular))
- add DSCR to influxdb2 repo  [\#16](https://github.com/puppetlabs/influxdb/pull/16) ([MartyEwings](https://github.com/MartyEwings))

## [v0.2.1](https://github.com/puppetlabs/influxdb/tree/v0.2.1) (2022-03-07)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.2.0...v0.2.1)

### Fixed

- Check use\_ssl is not nil [\#11](https://github.com/puppetlabs/influxdb/pull/11) ([ryanjbull](https://github.com/ryanjbull))

## [v0.2.0](https://github.com/puppetlabs/influxdb/tree/v0.2.0) (2022-03-01)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.1.0...v0.2.0)

### Added

- Use a mixin module instead of inheritance [\#7](https://github.com/puppetlabs/influxdb/pull/7) ([m0dular](https://github.com/m0dular))
- Add puppet-strings documentation [\#1](https://github.com/puppetlabs/influxdb/pull/1) ([m0dular](https://github.com/m0dular))

### Fixed

- Fix fqdn in install error message [\#3](https://github.com/puppetlabs/influxdb/pull/3) ([m0dular](https://github.com/m0dular))

## [v0.1.0](https://github.com/puppetlabs/influxdb/tree/v0.1.0) (2021-12-13)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.0.2...v0.1.0)

## [v0.0.2](https://github.com/puppetlabs/influxdb/tree/v0.0.2) (2021-11-18)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/v0.0.1...v0.0.2)

## [v0.0.1](https://github.com/puppetlabs/influxdb/tree/v0.0.1) (2021-11-16)

[Full Changelog](https://github.com/puppetlabs/influxdb/compare/ee8ed1c47240e3712966f9e651749528a5235160...v0.0.1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
