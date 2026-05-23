# AGENTS.md - Code Mode

Coding-specific rules for the Podman Provider project.

## YAML Editing Rules

### provider.yaml Modifications
- Lines 77-463 contain bash script as YAML string literal
- Preserve exact indentation (2 spaces per level from line 79)
- Use `|-` for multi-line strings to preserve newlines
- Test with `yamllint provider.yaml` after every change
- Never use tabs - only spaces

### String Escaping in YAML
- Double quotes inside bash strings: use single quotes or escape with backslash
- Heredocs (<<EOF) work but require careful indentation
- Variable expansion `${VAR}` is DevPod syntax, not bash - don't escape the `$`

## Bash Script Patterns

### Error Handling Pattern
```bash
if [ condition ]; then
  >&2 echo "Error: description"
  >&2 echo ""
  >&2 echo "Manual fix:"
  >&2 echo "  command here"
  >&2 echo ""
  >&2 echo "Or enable automation:"
  >&2 echo "  devpod provider set-options podman OPTION=value"
  exit 1
fi
```

### Platform Detection
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS-specific code (Machine management)
else
  # Linux code (direct daemon)
fi
```

### JSON Parsing Pattern
```bash
# Extract from podman machine inspect output
VALUE=$(echo "$JSON" | grep -o '"Field": *[0-9]*' | awk '{print $2}')
```

## Test Update Requirements

### When Changing exec.init Logic
1. **test_init_script.sh**: Update if changing machine detection, startup, or connectivity
2. **integration_test.sh**: Update if adding new provider options
3. **test_mismatch_detection.sh**: Update if changing resource comparison logic

### Test Environment Variables
- Use lower resource values than defaults (e.g., 2048MB vs 4096MB)
- Set `PODMAN_MACHINE_AUTO_INIT=false` unless testing auto-creation
- Always export variables before running test scripts

## Common Pitfalls

### Line Number References
- When adding/removing lines in exec.init, update line number comments in AGENTS.md
- Resource mismatch logic spans lines 182-446 (as of v0.4.0)

### Variable Defaults
- Use `${VAR:-default}` pattern for all optional variables
- Match defaults in provider.yaml options section
- Example: `${PODMAN_MACHINE_CPUS:-2}` matches line 52 default

### Machine Name Handling
- Always remove trailing `*` from active machine name (line 102)
- Check for empty string after auto-detection
- Don't assume machine name is alphanumeric only