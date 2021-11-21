# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][]

## [1.4.3][] - 2021-11-13

### Fixed

- Fix crash when rollbacking

## 1.4.2 - 2021-09-25

### Added

- Add more "Food Timer" options (4-24 minutes)

### Fixed

- Fix issue with persistent data between cave and forest

## 1.4.1 - 2021-06-21

### Changed

- Increase the frame-error validity for non-meat foods

## 1.4.0 - 2021-06-06

### Added

- Add "Time Persistence" configuration
- Add buffs persistent data support

## 1.3.1 - 2020-04-10

### Fixed

- Fix issue with non-removed negative timers

## 1.3.0 - 2021-03-06

### Added

- Add food buff timers support
- Add spice buffs support

### Fixed

- Fix crash with `nil` hunger, sanity and/or health values
- Fix issue with timer desyncing from the saved values

## 1.2.0 - 2020-12-18

### Added

- Add "Portal Delete Memory" configuration

### Changed

- Refactor food widgets

### Fixed

- Fix crash when a food is gone
- Fix issue when saved foods are getting swapped
- Fix issue with negative timers

## 1.1.0 - 2020-12-16

### Changed

- Refactor some parts

### Fixed

- Fix issue with missing timers for non-food type dishes (Sweet Tea, Wet Goop, etc.)
- Fix issue with missing timers for some non-crockpot dishes

## 1.0.0 - 2020-10-24

First release.

[unreleased]: https://github.com/dstmodders/mod-warly-memory/compare/v1.4.3...HEAD
[1.4.3]: https://github.com/dstmodders/mod-warly-memory/compare/v1.4.2...v1.4.3
