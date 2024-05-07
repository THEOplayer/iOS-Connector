# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- SideloadedSubtitle
  - Added `automaticTimestampSyncEnabled` API on `SSTextTrackDescription`.

### Fixed

- Conviva
  - Fixed an issue where reported contentInfo was not cleaned up correctly when starting a new viewing session.
  - Fixed an issue where c3.ad.technology was reported as an integer value instead of a string.

## [7.2.0] - 2024-04-24

### Fixed

- SideloadedSubtitle
  - Fixed an issue where playlists that contain urls with percentEncoding got an extra percentEncoding pass resulting in erronneous urls.
  - Fixed an issue where variant playlists with additional tags between EXTINF and the segment url, where not properly processed.

## [7.0.0] - 2024-04-03

### Changed

- Conviva 
  - Aligned the API to THEOplayer's Android and Web Conviva connectors.
  - Shield Conviva analytics endpoints. All data reporting now happens via the API.
  - Removed the 'report' methods for AssetName and ViewerID. These are replaced by using the setcontentInfo method (for viewerId) and by passing metadata to the sources (for AssetName).
  
## Added

- Conviva
  - VPF (Video Playback Failure) detection

## [6.8.1] - 2024-01-18

### Fixed

- Conviva
  - Updated deprecated name for access log notification to fix broken bitrate reporting.
  
- Comscore
  - Prevent Comscore connector crash when reporting ad info for a DAI stream
  
### Changed

- Conviva 
  - Dropped the protocol dependency for the external event dispatcher.

## [6.1.1] - 2023-10-06

### Fixed

- SideloadedSubtitle
  - Add iOS 17 compatibility

## [6.0.1] - 2023-09-27

### Fixed

- SideloadedSubtitle
  - adjust content string encoder in transformer

## [6.0.0] - 2023-09-26

### Fixed

- SideloadedSubtitle
  - urlDecode the contentUrl string before downloading the track
  - resolve relative uri params in quality playlists

## [5.11.0] - 2023-09-14

### Fixed

- SideloadedSubtitle
  - Take into account playlist redirects

## [5.9.1] - 2023-08-24

### Added

- SideloadedSubtitle
  - Sideloaded subtitle connector now supports: SRT text tracks, specifying a time offset and caching for offline playback.

## [5.7.0] - 2023-07-28

### Added

- Conviva
  - Added additional Ad metadata properties

## [5.5.1] - 2023-06-29

### Fixed

- Conviva
  - Reset stored bitrate value on source changes
  
### Added

- Conviva
  - Send c3.csid and contentAssetName as adMetadata on AdBegin event

## [5.4.2] - 2023-06-21

### Fixed

- Conviva
  - Reporting bitrates after start and stop new session.

## [5.2.0] - 2023-05-31

### Added

- SideloadedSubtitle
  - Added new connector to sideload subtitles on tvOS and iOS

## [5.1.0] - 2023-05-15

### Fixed

- Conviva
  - Do not use ads API when there is no ad integration on the THEOplayer
  - Fix example with custom built framework

## [5.0.5] - 2023-04-27

### Added

- Conviva
  - Reporting bitrates for ads (0af67a3c)

### Fixed

- Comscore
  - Prevent crash that sometimes happened during playback (75e9eacb)
- Conviva
  - Fixed a bug that would cause the connector to not report bitrates when using manifest interception on the THEOplayer via the developer settings. (6ee5e519)

### Changed

- Conviva
  - Report bitrates from iOS in kbps to conviva (a231831a)
  - Do not report empty sessions (4257d803)


## [5.0.4] - 2023-04-21

### Changed

- Conviva
  - Report false as default for `CIS_SSDK_METADATA_IS_LIVE` (6bb45c17)

## [5.0.3] - 2023-04-17

### Added

- Conviva
  - Report ad resourceURI’s (a6b158d9)

## [5.0.2] - 2023-04-14

### Added

- Conviva
  - Report rendered framerate (c5e272d1)
  - Report ended when deinitialised (f49d2bb0)
  - Report network errors (02930576)

## [5.0.1] - 2023-04-13

### Changed

- Conviva
  - Do not report duration if no source is set (64db6846)

## [5.0.0] - 2023-04-07

### Fixed

- Comscore
  - Call notifyPlay when playback resumes after seek (9420ec5f)
  - Don't pause the player on background move (df92e0ff)

### Changed

- Comscore
  - Changed THEOplayer cocoapod dependency from `THEOplayerSDK-basic` to `THEOplayerSDK-core`
  - Changed minimum version requirement of ComScore from `6.7.1` to `6.10.0`
- Nielsen
  - Changed THEOplayer cocoapod dependency from `THEOplayerSDK-basic` to `THEOplayerSDK-core`
- Conviva
  - Changed THEOplayer cocoapod dependency from `THEOplayerSDK-basic` to `THEOplayerSDK-core`

## [4.6.0] - 2023-04-05

### Added

- Conviva
  - Report player framework info for ads (ececcab0)
  - Read duration of ads from THEOplayer instance (54a51109)

### Changed

- Conviva
  - Report a default value of `"NA"` for `CIS_SSDK_METADATA_ASSET_NAME` (6c4ba003)
- Nielsen
  - Only report ended if played to Nielsen (639c08c1)
  - Remove length metadata reporting (c53642b9)

### Removed

- Conviva
  - Removed backgrounding logs from stdout (ccb64d05)

## [4.5.1] - 2023-03-30

### Fixed

- Comscore
  - Fixed a crash that happened when removing the connector (36c30950)

### Removed

- Nielsen
  - removed the following DCR reports (cc14c08c):
    - playheadPosition
    - play
    - loadMetadata

## [4.5.0] - 2023-03-24

### Added

- Comscore
  - Added Comscore connector

## [4.4.0] - 2023-03-21

### Added

- Nielsen
  - Readme (62afa92c)

### Changed

- Nielsen
  - Use `NielsenAppSDK` and `NielsenTVOSAppSDK` dependencies for cocoapod instead of `NielsenAppSDK-XC` (ded687d0)


## [4.3.1] - 2023-03-17

### Added

- Nielsen
  - Report play, stop and end events (b737b336)
  - Report ID3 tags, metadata and duration changes (f4118e19)
  - Report Ad events (47ab93e6)
- Utilities
  - Shared package with utilities that can be reused for multiple connectors

## [4.3.0] - 2023-03-02

### Added

- Nielsen
  - Setup target for SPM (33b5ff6c)
- Conviva
  - Added tvOS platform to cocoapod (d4ea17dc)


### Changed

- Conviva
  - Round `CIS_SSDK_METADATA_DURATION` to closest integer (105ddf96)
  - Report metrics in milliseconds instead of seconds (105ddf96):
    - `CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME`
    - `CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED`
    - `CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED`
  - Only report non-linear ad types. (39edc330)
  - Report “NA” for `CIS_SSDK_METADATA_ASSET_NAME` when no title is provided. (90c86a4c)
  - Close session after fatal error (ce6bcd27)
  - Report `THEOplayer.version` instead of `.playerSuiteVersion` for Conviva's `CIS_SSDK_PLAYER_FRAMEWORK_VERSION` metric (9e1eb3c8)

### Removed

- Conviva
  - Removed unneeded playing report during ads (51670e42)

## [4.2.0] - 2023-02-21

### Added

- Conviva
  - Automatic reporting of `CIS_SSDK_METADATA_ASSET_NAME` from THEOplayer's `metadata.title` inside the current source's `SourceDescription` (f4c59570)


## [4.1.1] - 2022-10-19

### Added

- Conviva connector
- Conviva-VerizonMedia connector

[unreleased]: https://github.com/THEOplayer/iOS-Connector/compare/5.4.2...HEAD
[5.4.2]: https://github.com/THEOplayer/iOS-Connector/compare/5.2.0...5.4.2
[5.2.0]: https://github.com/THEOplayer/iOS-Connector/compare/5.1.0...5.2.0
[5.1.0]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.5...5.1.0
[5.0.5]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.4...5.0.5
[5.0.4]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.3...5.0.4
[5.0.3]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.2...5.0.3
[5.0.2]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.1...5.0.2
[5.0.1]: https://github.com/THEOplayer/iOS-Connector/compare/5.0.0...5.0.1
[5.0.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.6.0...5.0.0
[4.6.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.5.1...4.6.0
[4.5.1]: https://github.com/THEOplayer/iOS-Connector/compare/4.5.0...4.5.1
[4.5.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.4.0...4.5.0
[4.4.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.3.1...4.4.0
[4.3.1]: https://github.com/THEOplayer/iOS-Connector/compare/4.3.0...4.3.1
[4.3.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.2.0...4.3.0
[4.2.0]: https://github.com/THEOplayer/iOS-Connector/compare/4.1.1...4.2.0
[4.1.1]: https://github.com/THEOplayer/iOS-Connector/releases/tag/4.1.1

