# AGENTS.md - Advanced Mode

Advanced coding rules for complex refactoring and architectural changes.

## Architecture Constraints

### Single-File Design Philosophy
- All logic MUST remain in `provider.yaml` exec.init section
- Do not create separate shell scripts or helper binaries
- DevPod provider model requires self-contained YAML file
- Future extensions should use `binaries` section if external tools needed

### State Management
- No persistent state storage - provider is stateless
- Machine state is queried on every init (no caching)
- Resource configuration stored only in DevPod provider options
- Machine configuration stored in Podman Machine itself

## Refactoring Guidelines

### When to Split Logic
- **Never split exec.init into separate files** - breaks DevPod model
- Can extract repeated patterns into bash functions within exec.init
- Consider heredocs for complex multi-line outputs
- Keep platform branching at top level (macOS vs Linux)

### Performance Considerations
- `podman machine inspect` is expensive - call once, parse multiple fields
- Avoid multiple `podman machine list` calls - cache result in variable
- Startup timeout loop uses 2-second intervals (lines 152-159, 331-338)
- JSON parsing with grep/awk is faster than jq but more fragile

## Breaking Changes

### When Adding New Options
1. Add to `options` section with description and default
2. Add to appropriate `optionGroups` for UI organization
3. Update exec.init to use `${NEW_OPTION:-default}` pattern
4. Update all README files (English and Japanese)
5. Add test coverage in integration_test.sh
6. Update CHANGELOG.md with migration notes

### Deprecating Options
- Never remove options - mark as deprecated in description
- Maintain backward compatibility for at least 2 major versions
- Document migration path in CHANGELOG.md
- Add warning message in exec.init if deprecated option is used

## Complex Scenarios

### Multi-Machine Support
- Current implementation auto-detects first machine
- Explicit `PODMAN_MACHINE_NAME` overrides auto-detection
- No support for parallel machine management
- Switching machines requires provider option change

### Resource Update Atomicity
- Updates are NOT atomic - applied sequentially (lines 275-312)
- Partial failure leaves machine in inconsistent state
- No rollback mechanism - manual recovery required
- Consider adding transaction-like wrapper in future

### Error Recovery Strategies
- Machine stop failure (line 265): Cannot proceed, exit immediately
- Machine start failure (line 317): Inconsistent state, manual intervention needed
- Resource update failure (lines 277-311): Continue with other updates, warn user
- Timeout (lines 161, 341): Exit with clear error message and timeout increase suggestion

## Future Extension Points

### Potential MCP Integration
- Machine management could be exposed as MCP tools
- Resource inspection could be MCP resource
- Would require separate MCP server implementation
- Provider.yaml would call MCP server via binaries section

### Plugin Architecture
- DevPod providers don't support plugins
- Extensions must be in exec.init or binaries section
- Consider feature flags via options for experimental features