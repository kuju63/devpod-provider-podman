# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.3.0] - 2026-02-09

### Added
- Provider icon in DevPod Desktop UI for better visual identification (#8)
- Translation skill for automated document translation (Claude Code integration)
- Contributor Covenant Code of Conduct v2.1
- Multi-language documentation support (English and Japanese)
  - README.md (English, primary)
  - README.ja.md (Japanese)
  - tests/README.md (English)
  - tests/README.ja.md (Japanese)

### Changed
- CLAUDE.md now in English with expanded developer guidance
- Added test flow diagrams (Mermaid) for development workflow visualization
- Translation glossary moved to separate file (.claude/skills/translate/glossary.md)
- Improved Conventional Commits documentation with examples

## [v0.2.1] - 2026-02-08

### Fixed
- Machine name detection now correctly strips trailing asterisk from active machines (#7)
- Resolves "VM does not exist" errors when using auto-detected machine names

## [v0.2.0] - 2026-02-08

### Added
- Non-destructive in-place resource updates using `podman machine set`
- New option: `PODMAN_MACHINE_AUTO_RESOURCE_UPDATE` (default: `false`)
- Automatic machine stop/update/start flow for resource configuration changes
- Enhanced warning messages with both destructive and non-destructive update options

### Changed
- Improved error handling for disk size reduction attempts (increase only supported)
- Better logging for configuration changes and update operations

## [v0.1.0] - 2026-02-07

### Added
- macOS Podman Machine auto-management and resource configuration
- Resource configuration options (CPU, Memory, Disk, Rootful mode)
- Machine auto-initialization with `PODMAN_MACHINE_AUTO_INIT`
- Machine auto-start with `PODMAN_MACHINE_AUTO_START`
- Resource mismatch detection and warning system
- Detailed error messages with manual and automated resolution guidance

### Changed
- Organized options into three groups: Basic, Machine Management, Machine Resources
- Enhanced init script with platform detection and machine state management

## [v0.0.1] - 2026-02-06

### Added
- Initial DevPod provider implementation for Podman
- Basic provider functionality with Docker-compatible driver
- Podman path configuration option
- Command execution support via `podman exec`
