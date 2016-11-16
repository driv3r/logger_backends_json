# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Normalize error logger messages, use `inspect` for now.

### Changed
- Push messages to `:user` process intead of group leader, as error handler can actually have different group leader than the running process.

## [0.1.0] - 2016-11-15
### Added
- Base json backend implementation.
