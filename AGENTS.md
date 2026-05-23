# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Critical Architecture Constraints

### Single-File Implementation
- **ALL provider logic is embedded in `provider.yaml` lines 77-463** (exec.init section)
- No separate shell scripts or binaries - everything is YAML-embedded bash
- Modifying logic requires careful YAML string literal handling (indentation, escaping, heredocs)
- Syntax errors are NOT detected until DevPod runtime execution

### Platform-Specific Branching
- macOS: Requires Podman Machine VM management (`[[ "$OSTYPE" == "darwin"* ]]`)
- Linux: Direct daemon connection (no Machine management)
- **Do not assume cross-platform behavior** - test both paths separately

### Resource Mismatch Detection Logic (Lines 182-446)
- Only runs when `PODMAN_MACHINE_AUTO_INIT != "true"` (line 182)
- Uses grep/awk to parse JSON from `podman machine inspect` (lines 186-189)
- Rootful normalization: treats `true`, `"true"`, and `1` as equivalent (lines 198-201)
- Disk size decrease is explicitly blocked (lines 250-261)
- Two execution paths: auto-update (lines 229-370) or warning display (lines 371-443)

### Machine Name Resolution
- Line 102: Removes trailing asterisk (`*`) from active machine name
- Empty `PODMAN_MACHINE_NAME` triggers auto-detection (line 101)
- Auto-detection uses first machine from list (may not be the active one)

## Non-Obvious Behaviors

### Default Values in provider.yaml
- `PODMAN_MACHINE_AUTO_START=true` (line 37) - machines auto-start by default
- `PODMAN_MACHINE_AUTO_INIT=false` (line 41) - machines do NOT auto-create by default
- `PODMAN_MACHINE_AUTO_RESOURCE_UPDATE=false` (line 68) - resource updates require opt-in
- Memory default is 4096MB (line 56), not 2048MB used in tests

### Error Message Design Pattern
- All errors output to stderr with `>&2 echo`
- Every error includes both manual fix AND automation option
- Example structure: "Manual fix: <command>" followed by "Or enable: <devpod command>"

### Test-Code Divergence
- `tests/test_init_script.sh` uses `PODMAN_MACHINE_MEMORY=2048` (line 15)
- `provider.yaml` defaults to `PODMAN_MACHINE_MEMORY=4096` (line 56)
- Tests intentionally use lower values for faster execution

## Hidden Dependencies

### Podman Version Requirements
- `podman machine set` requires Podman v4.0+ (not validated in code)
- Resource updates will silently fail on older versions
- No version check for `machine set` compatibility

### Machine State Transitions
- Resource updates require machine to be stopped (line 265)
- Startup timeout applies after resource updates (lines 327-343)
- Failed resource update leaves machine in stopped state (line 269 exit)

### JSON Parsing Fragility
- Lines 186-189: grep/awk parsing assumes specific JSON format from `podman machine inspect`
- No fallback if JSON structure changes in future Podman versions
- Parsing fails silently if fields are missing (empty string results)

## Testing Requirements

### When Modifying exec.init (Lines 77-463)
1. Update `tests/test_init_script.sh` for logic changes
2. Update `tests/integration_test.sh` for new options
3. Update `tests/test_mismatch_detection.sh` for resource detection changes
4. Test both macOS and Linux paths (if applicable)

### Manual Test Scenarios Required
- TS7: Resource mismatch warning display (AUTO_INIT=false)
- TS8: No warning on new machine creation (AUTO_INIT=true)
- Disk size decrease attempt (should fail with specific error)

## Documentation Synchronization

### Multi-Language Files
- `README.md` (English, primary) and `README.ja.md` (Japanese) must stay synchronized
- `tests/README.md` and `tests/README.ja.md` must stay synchronized
- Code examples must be identical across language versions
- Use `.claude/skills/translate/glossary.md` for term consistency

### Translation Glossary
- 56 software development terms defined in `.claude/skills/translate/glossary.md`
- Must be consulted before adding new technical terms to documentation
- Inconsistent terminology breaks user experience across languages

## Dangerous Operations

### YAML String Literal Editing
- Bash script in `provider.yaml` is a multi-line string literal
- Incorrect indentation breaks YAML parsing
- Heredocs inside YAML strings require careful escaping
- Always validate with `yamllint provider.yaml` after changes

### Resource Update Edge Cases
- Disk size decrease: explicitly blocked but user might force it manually
- Rootful mode change: requires machine restart, may affect existing containers
- Memory/CPU decrease: allowed but may cause OOM or performance issues
- Multiple simultaneous updates: applied sequentially, partial failure possible

### Machine State Assumptions
- Code assumes `podman machine inspect` returns valid JSON (no error handling)
- Code assumes machine name doesn't contain special characters
- Code assumes `podman ps` succeeds if machine is running (lines 153, 332)

## Version-Specific Behaviors

### v0.4.0 Features
- Non-destructive resource updates via `podman machine set`
- Automatic resource update option (`PODMAN_MACHINE_AUTO_RESOURCE_UPDATE`)
- Disk size decrease detection and blocking
- Enhanced warning messages with two-option format

### Backward Compatibility
- Pre-v0.2.1: No asterisk removal (line 102), may fail with active machine
- Pre-v0.3.0: No resource mismatch detection
- Pre-v0.4.0: No automatic resource updates, only warnings