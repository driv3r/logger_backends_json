# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.4.1] - 2016-11-23
### Removed
- Removed config_ext from included applications.

## [0.4.0] - 2016-11-23
### Added
- Extracted `Event` module from logger backend.
- Allow `event` as configuration option, you can provide custom `Event` module.
- Allow custom filtering and building of messages.

## [0.3.2] - 2016-11-23
### Added
- transform log level to atom

## [0.3.1] - 2016-11-22
### Removed
- Leftover and unused `fetch` function.

## [0.3.0] - 2016-11-22
### Changed
- Use `ConfigExt` instead of custom function execution.

## [0.2.0] - 2016-11-16
### Added
- Normalize error logger messages, use `inspect` for now.

### Changed
- Push messages to `:user` process intead of group leader, as error handler can actually have different group leader than the running process.

## [0.1.0] - 2016-11-15
### Added
- Base json backend implementation.
