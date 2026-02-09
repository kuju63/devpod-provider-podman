# CHANGELOG Entry Template

This template follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

## Structure

```markdown
## [VERSION] - YYYY-MM-DD

### Added
- New features and capabilities

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

## Category Mappings

When parsing Conventional Commits, map commit types to CHANGELOG categories:

| Commit Type | CHANGELOG Category |
|-------------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `docs:` | Changed |
| `chore:` | Changed |
| `refactor:` | Changed |
| `test:` | Changed |
| `perf:` | Changed |
| `style:` | Changed |
| `build:` | Changed |
| `ci:` | Changed |
| `revert:` | Changed |

## Issue References

Convert issue numbers to GitHub links:
- Input: `#123` or `Refs: #123` or `Closes #123`
- Output: `[#123](https://github.com/kuju63/podman-provider/issues/123)`

## Example Entry

```markdown
## [v0.4.0] - 2026-02-10

### Added
- Automatic resource update with podman machine set [#42](https://github.com/kuju63/podman-provider/issues/42)
- Support for user namespaces in containers [#45](https://github.com/kuju63/podman-provider/issues/45)
- Dry-run mode for init script validation

### Changed
- Improved error messages with actionable solutions [#43](https://github.com/kuju63/podman-provider/issues/43)
- Updated documentation with troubleshooting guide
- Refactored machine name detection logic

### Fixed
- Handle podman machine names with asterisk (*) [#41](https://github.com/kuju63/podman-provider/issues/41)
- Resolve race condition in machine initialization [#44](https://github.com/kuju63/podman-provider/issues/44)
```

## Breaking Changes Section

For major version bumps, add a Breaking Changes section at the top:

```markdown
## [v1.0.0] - 2026-02-10

### ⚠️ Breaking Changes
- Removed deprecated PODMAN_MACHINE_AUTO_INIT option
- Changed default CPU count from 2 to 4
- Requires Podman v4.0 or later

### Added
...
```

## Insertion Point

Insert the new entry **after line 7** in CHANGELOG.md, which is after the `## [Unreleased]` section:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [v0.4.0] - 2026-02-10  <-- INSERT NEW ENTRY HERE
...

## [v0.3.0] - 2026-02-09
...
```

## Formatting Rules

1. **Version format**: `[vX.Y.Z]` with brackets
2. **Date format**: `YYYY-MM-DD` (ISO 8601)
3. **Categories**: Use H3 headings (`###`)
4. **Items**: Use unordered lists with `-`
5. **Links**: Use markdown link syntax
6. **Empty categories**: Omit if no items
7. **Spacing**: One blank line between categories, two blank lines between versions

## Quality Checklist

- [ ] Version matches semantic versioning (vX.Y.Z)
- [ ] Date is correct (YYYY-MM-DD)
- [ ] All commits are categorized correctly
- [ ] Issue references are linked
- [ ] No empty category sections
- [ ] Consistent formatting throughout
- [ ] Breaking changes highlighted if present
