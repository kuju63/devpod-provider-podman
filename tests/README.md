# DevPod Podman Provider - Test Suite

**Languages / 言語:** [English](README.md) | [日本語](README.ja.md)

This directory contains test scripts for the Phase 2 implementation.

## Test Scripts

### 1. `test_init_script.sh`
Tests basic operations of the initialization script.

**Test Coverage:**
- Podman binary existence check
- Podman version retrieval
- Platform detection (macOS/Linux)
- Automatic Machine name detection
- Machine state verification
- Connection test

**Execution:**
```bash
cd tests
chmod +x test_init_script.sh
./test_init_script.sh
```

**Expected Results:**
- All checks display checkmarks (✓)
- Completes without errors

### 2. `integration_test.sh`
Executes integration tests as a DevPod provider.

**Test Coverage:**
- Provider registration
- Options list verification
- Custom option configuration
- Option value validation
- Cleanup

**Execution:**
```bash
cd tests
chmod +x integration_test.sh
./integration_test.sh
```

**Expected Results:**
- All 4 tests succeed (✓)
- Cleanup completes

### 3. `test_mismatch_detection.sh`
Tests resource configuration mismatch detection logic (Phase 3 addition).

**Test Coverage:**
- CPU configuration mismatch detection
- Memory configuration mismatch detection
- Disk size mismatch detection
- Rootful mode configuration mismatch detection
- Multiple simultaneous mismatch detection
- Matching configuration validation
- Rootful value normalization (true/false/1 normalization)

**Execution:**
```bash
cd tests
chmod +x test_mismatch_detection.sh
./test_mismatch_detection.sh
```

**Expected Results:**
- All tests succeed (✓ 7/7)
- Each test correctly detects mismatch/match

## Prerequisites

Before running tests, the following must be installed:

- **Podman**: `brew install podman`
- **DevPod**: `brew install devpod`
- **macOS**: Required for testing Podman Machine functionality (basic tests work on Linux)

## Test Environment

Tests have been verified in the following environment:

- macOS (Darwin)
- Podman 5.x or later
- DevPod 0.5.x or later

## Troubleshooting

### Test Failures

1. **Podman Machine is not running**
   ```bash
   podman machine start
   ```

2. **Old test provider remains**
   ```bash
   devpod provider delete podman-phase2-test
   ```

3. **Permission errors**
   ```bash
   chmod +x tests/*.sh
   ```

## CI/CD Integration

These tests can be integrated into CI/CD pipelines such as GitHub Actions.

```yaml
# Example .github/workflows/test.yml
- name: Run tests
  run: |
    chmod +x tests/*.sh
    ./tests/test_init_script.sh
    ./tests/integration_test.sh
```

## Manual Test Scenarios

In addition to automated tests, the following scenarios are recommended for manual testing:

### TS1: Machine Not Created Environment
```bash
# Delete Machine
podman machine stop
podman machine rm

# Verify error message with AUTO_INIT=false (default)
devpod provider add ./provider.yaml

# Auto-create with AUTO_INIT=true
devpod provider set-options podman -o PODMAN_MACHINE_AUTO_INIT=true
```

### TS2: Custom Resource Configuration
```bash
devpod provider set-options podman \
  -o PODMAN_MACHINE_CPUS=4 \
  -o PODMAN_MACHINE_MEMORY=8192 \
  -o PODMAN_MACHINE_DISK_SIZE=200 \
  -o PODMAN_MACHINE_AUTO_INIT=true

# Recreate Machine
podman machine rm
devpod up <test-repo> --provider podman

# Verify resources
podman machine inspect
```

### TS3: Stopped Machine Auto-start
```bash
# Stop Machine
podman machine stop

# Create workspace with DevPod (auto-starts)
devpod up <test-repo> --provider podman
```

### TS4: Multiple Machine Environment
```bash
# Create multiple Machines
podman machine init machine1
podman machine init machine2

# Specify particular Machine
devpod provider set-options podman -o PODMAN_MACHINE_NAME=machine1
```

### TS5: Timeout Test
```bash
# Set short timeout
devpod provider set-options podman -o PODMAN_MACHINE_START_TIMEOUT=5

# Stop Machine and test startup
podman machine stop
devpod up <test-repo> --provider podman
```

### TS6: Rootful Mode
```bash
# Create Machine in rootful mode
devpod provider set-options podman \
  -o PODMAN_MACHINE_ROOTFUL=true \
  -o PODMAN_MACHINE_AUTO_INIT=true

# Recreate after Machine deletion
podman machine rm
devpod up <test-repo> --provider podman

# Verify rootful configuration
podman machine inspect | grep -i rootful
```

### TS7: Resource Configuration Change Warning (Phase 3 Addition)
```bash
# Prerequisite: Existing Machine running with CPU=2, Memory=2048

# Change resource configuration (displays warning with AUTO_INIT=false)
devpod provider set-options podman \
  -o PODMAN_MACHINE_CPUS=8 \
  -o PODMAN_MACHINE_MEMORY=4096

# Warning displayed on workspace startup
devpod up <test-repo> --provider podman

# Expected warning message:
# ⚠️  WARNING: Machine resource configuration mismatch detected
# Configuration differences:
#   • CPUs: Current=2, Desired=8
#   • Memory: Current=2048MB, Desired=4096MB
```

### TS8: No Warning on New Machine Creation (Phase 3 Addition)
```bash
# Delete Machine
podman machine stop
podman machine rm

# Enable AUTO_INIT
devpod provider set-options podman \
  -o PODMAN_MACHINE_AUTO_INIT=true \
  -o PODMAN_MACHINE_CPUS=8 \
  -o PODMAN_MACHINE_MEMORY=4096

# Create new Machine on workspace startup
devpod up <test-repo> --provider podman

# Expected behavior:
# - New Machine created (no warning)
# - Specified resources (CPU=8, Memory=4096) applied at creation
```

### TS9: Release Asset Verification

Verify that GitHub releases include provider.yaml asset for DevPod installation.

**Prerequisites**:
```bash
# Requires a published release (e.g., v0.3.0)
# Verify release exists
gh release list
```

**Test Steps**:
```bash
# Step 1: Verify asset is attached to release
gh release view v0.3.0 | grep "provider.yaml"
# Expected: Shows "provider.yaml" in assets list

# Step 2: Download provider.yaml from latest release
curl -L https://github.com/kuju63/devpod-provider-podman/releases/latest/download/provider.yaml -o /tmp/provider-test.yaml
# Expected: File downloaded successfully (HTTP 200)

# Step 3: Verify file is valid YAML
yamllint /tmp/provider-test.yaml
# Expected: No syntax errors

# Step 4: Test DevPod installation from GitHub release
devpod provider add github.com/kuju63/devpod-provider-podman
devpod provider use podman
devpod provider list | grep podman
# Expected: Provider installed and listed

# Step 5: Verify provider version matches release
devpod provider list | grep "podman.*v0.3.0"
# Expected: Version matches release tag

# Cleanup
devpod provider delete podman
rm /tmp/provider-test.yaml
```

**Expected Results**:
- Asset appears in `gh release view` output
- provider.yaml downloads successfully from `/latest/download/` path
- YAML syntax is valid
- DevPod can install provider directly from GitHub URL
- Provider version matches release tag

## Reporting

Test results are displayed in standard output. If errors occur, detailed error messages and guidance will be shown.
