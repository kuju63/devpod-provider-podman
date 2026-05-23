# AGENTS.md - Plan Mode

Architecture and design constraints for planning new features.

## Design Principles

### Simplicity Over Flexibility
- Single-file implementation is intentional, not a limitation
- Avoid over-engineering - this is a thin wrapper around Podman
- User-facing options should have sensible defaults
- Automation should be opt-in, not forced

### Fail-Fast Philosophy
- Detect problems early in exec.init, not during workspace creation
- Clear error messages with actionable solutions
- Prefer explicit failures over silent degradation
- Every error must show both manual fix and automation option

## Architecture Decisions

### Why Single-File Implementation?
- DevPod provider model expects self-contained YAML
- Simplifies distribution and installation
- No dependency management needed
- Easy to audit and understand

### Why No State Persistence?
- Podman Machine is the source of truth
- DevPod provider options store user preferences
- Querying state on every init ensures consistency
- Avoids state synchronization bugs

### Why Platform Branching?
- macOS requires VM (Podman Machine)
- Linux uses native containers (no VM)
- Cannot abstract away fundamental platform differences
- Better to have explicit branches than hidden assumptions

## Feature Planning Guidelines

### Before Adding New Options
1. **Is it necessary?** Can existing options solve the problem?
2. **Is it safe?** What happens if user sets wrong value?
3. **Is it testable?** Can we write automated tests?
4. **Is it documented?** Can users understand what it does?
5. **Is it translatable?** Can we explain it in Japanese?

### Before Adding New Automation
1. **Is it opt-in?** Don't surprise users with automatic actions
2. **Is it reversible?** Can users undo the automation?
3. **Is it idempotent?** Safe to run multiple times?
4. **Is it observable?** Do users see what's happening?

## Known Limitations

### Cannot Support
- **Windows**: Podman Machine on Windows uses WSL2, different architecture
- **Rootless on macOS**: Podman Machine is always VM-based
- **Container-in-container**: DevPod workspace is already in container
- **Multi-machine parallel use**: Provider model assumes single environment

### Difficult to Support
- **Custom machine drivers**: Podman Machine supports QEMU/HVF/Hyper-V
- **Network customization**: Limited by Podman Machine capabilities
- **Volume driver selection**: Podman Machine uses default driver
- **GPU passthrough**: Requires Podman Machine support first

## Future Feature Considerations

### Resource Hot-Reload
- **Current**: Requires machine stop/start
- **Desired**: Update without stopping
- **Blocker**: Podman Machine limitation
- **Workaround**: Use `podman machine set` (requires stop)

### Multi-Machine Orchestration
- **Current**: One machine per provider instance
- **Desired**: Manage multiple machines
- **Blocker**: DevPod provider model (one environment)
- **Workaround**: Multiple provider instances with different names

### Automatic Backup/Restore
- **Current**: No backup mechanism
- **Desired**: Backup before destructive operations
- **Blocker**: No standard backup format for Podman Machine
- **Workaround**: Document manual backup procedures

### Health Monitoring
- **Current**: One-time check in exec.init
- **Desired**: Continuous health monitoring
- **Blocker**: exec.init runs once, not continuously
- **Workaround**: Use DevPod's inactivity timeout for cleanup

## Integration Opportunities

### Claude Code Skills
- **Translation skill**: Already implemented (`.claude/skills/translate/`)
- **Release skill**: Already implemented (`.claude/skills/release/`)
- **Potential**: Testing skill, documentation generation skill

### GitHub Actions
- **Current**: Claude Code integration, auto code review
- **Potential**: Automated testing on PR, release automation
- **Blocker**: Need macOS runner for Podman Machine tests

### MCP (Model Context Protocol)
- **Potential**: Expose machine management as MCP tools
- **Potential**: Provide machine state as MCP resources
- **Blocker**: Requires separate MCP server implementation
- **Consideration**: Would add complexity to single-file design