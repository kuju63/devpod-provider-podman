# AGENTS.md - Ask Mode

Documentation and question-answering context for the Podman Provider project.

## Documentation Structure

### Multi-Language Documentation
- **Primary**: README.md (English) - authoritative version
- **Secondary**: README.ja.md (Japanese) - must stay synchronized
- **Test docs**: tests/README.md and tests/README.ja.md
- **Developer guide**: CLAUDE.md (English only)

### Translation Workflow
- Use `.claude/skills/translate/glossary.md` for term consistency
- 56 technical terms have standardized translations
- Code examples are never translated - must be identical
- Section structure must match between language versions

## Key Concepts to Explain

### DevPod Provider Model
- Providers are YAML files with embedded scripts
- `exec.init` runs before workspace creation
- `exec.command` wraps all workspace commands
- Options become environment variables at runtime

### Podman Machine (macOS-specific)
- Virtual machine required on macOS (not Linux)
- Manages QEMU/HVF virtualization
- Stores container images and volumes
- Can be stopped/started independently of containers

### Resource Configuration Lifecycle
1. **Creation**: Resources set during `podman machine init`
2. **Detection**: Mismatch detected on subsequent init
3. **Update**: Non-destructive via `podman machine set` (v4.0+)
4. **Recreation**: Destructive fallback (data loss)

## Common User Questions

### "Why does my machine have different resources?"
- Resources are set at machine creation time
- Changing provider options doesn't auto-update existing machine
- Two solutions: in-place update (safe) or recreation (destructive)
- See README.md "How to Change Resources" section

### "What's the difference between AUTO_START and AUTO_INIT?"
- `AUTO_START=true`: Start stopped machine (default, safe)
- `AUTO_INIT=true`: Create missing machine (opt-in, creates new VM)
- AUTO_START is enabled by default, AUTO_INIT is not
- AUTO_INIT useful for CI/CD or first-time setup

### "Can I use multiple Podman Machines?"
- Yes, but provider uses one machine at a time
- Set `PODMAN_MACHINE_NAME` to specify which machine
- Empty name triggers auto-detection (first machine found)
- No parallel machine management support

### "Why can't I decrease disk size?"
- Podman Machine limitation, not provider limitation
- Disk images can only grow, not shrink
- Attempting decrease shows clear error message (lines 250-261)
- Must recreate machine to use smaller disk (data loss)

## Documentation Maintenance

### When Adding Features
1. Update README.md with feature description
2. Translate to README.ja.md using glossary
3. Add configuration examples
4. Update troubleshooting section if needed
5. Add manual test scenario to tests/README.md
6. Update CHANGELOG.md

### When Fixing Bugs
1. Update troubleshooting section in README.md
2. Add diagnostic commands
3. Explain root cause if non-obvious
4. Synchronize with README.ja.md

## Reference Materials

### External Documentation
- DevPod: https://devpod.sh/docs/
- Podman: https://podman.io/docs/
- Podman Machine: https://docs.podman.io/en/latest/markdown/podman-machine.1.html

### Internal Documentation
- CLAUDE.md: Developer workflow, commit conventions, testing
- CHANGELOG.md: Version history, breaking changes
- tests/README.md: Test scenarios, manual testing procedures