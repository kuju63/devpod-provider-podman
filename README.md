# DevPod Podman Provider

**Languages / 言語:** [English](README.md) | [日本語](README.ja.md)

Podman Provider for DevPod

## Overview

This project provides a Podman container engine provider for [DevPod](https://devpod.sh/). DevPod is an open-source client-side development environment management tool, and this provider enables you to manage development workspaces using Podman containers.

## Features

- ✅ Create and manage development environments with Podman containers
- ✅ Automatic Podman Machine management on macOS
- ✅ Automatic Machine startup and initialization
- ✅ Customizable resource configuration (CPU, memory, disk)
- ✅ Non-destructive in-place resource updates (`podman machine set` support)
- ✅ Rootful/rootless mode selection
- ✅ Automatic stop on inactivity timeout
- ✅ Detailed error messages and guidance

## Prerequisites

### macOS

1. **Install Podman**:
   ```bash
   brew install podman
   ```

2. **Install DevPod CLI**:
   ```bash
   brew install devpod
   ```

**Note**: Podman Machine initialization and startup are handled automatically by default (`PODMAN_MACHINE_AUTO_START=true`). If you want to automatically create the Machine on first run, set `PODMAN_MACHINE_AUTO_INIT=true`.

## Usage

### Add the Provider

#### Local Development Version
```bash
cd /path/to/podman-provider
devpod provider add ./provider.yaml
devpod provider use podman
```

#### Via GitHub (After Publication)
```bash
devpod provider add https://github.com/kuju63/devpod-provider-podman
devpod provider use podman
```

### Create a Workspace
```bash
# Try with sample repository
devpod up https://github.com/loft-sh/devpod-example-go --provider podman

# Use your own repository
devpod up https://github.com/your/repository --provider podman
```

### Connect to a Workspace
```bash
devpod ssh <workspace-name>
```

### Delete a Workspace
```bash
devpod delete <workspace-name>
```

## Configuration Options

### Basic Options

| Option | Description | Default Value |
|--------|-------------|---------------|
| `PODMAN_PATH` | Path to Podman binary | `podman` |
| `INACTIVITY_TIMEOUT` | Auto-stop time on inactivity (e.g., 10m, 1h) | None |

### Machine Management (macOS Only)

| Option | Description | Default Value |
|--------|-------------|---------------|
| `PODMAN_MACHINE_AUTO_START` | Automatically start stopped Machine | `true` |
| `PODMAN_MACHINE_AUTO_INIT` | Automatically create Machine if not exists | `false` |
| `PODMAN_MACHINE_NAME` | Machine name to use (empty for auto-detection) | Auto-detect |
| `PODMAN_MACHINE_START_TIMEOUT` | Startup timeout (seconds) | `60` |

### Machine Resource Configuration

| Option | Description | Default Value |
|--------|-------------|---------------|
| `PODMAN_MACHINE_CPUS` | Number of CPUs | `2` |
| `PODMAN_MACHINE_MEMORY` | Memory (MB) | `4096` |
| `PODMAN_MACHINE_DISK_SIZE` | Disk size (GB) | `100` |
| `PODMAN_MACHINE_ROOTFUL` | Rootful mode (privileged operations, lower security) | `false` |
| `PODMAN_MACHINE_AUTO_RESOURCE_UPDATE` | Auto-update on resource mismatch detection (non-destructive) | `false` |

### Configuration Examples

```bash
# Basic configuration
devpod provider set-options podman PODMAN_PATH=/opt/homebrew/bin/podman

# Enable full automation
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true

# Resource configuration (applied on next Machine creation)
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=4 \
  PODMAN_MACHINE_MEMORY=8192 \
  PODMAN_MACHINE_DISK_SIZE=200
```

## Automatic Machine Management (macOS)

This provider automatically manages Podman Machine on macOS:

### Default Behavior

- **Auto-start**: Automatically starts stopped Machine (`PODMAN_MACHINE_AUTO_START=true`)
- **Manual creation**: Shows error when Machine doesn't exist (`PODMAN_MACHINE_AUTO_INIT=false`)

### Full Automation

To automatically create Machine on first run:

```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
```

This eliminates the need for manual Podman Machine setup.

### Specifying Machine Name

When using multiple Machines:

```bash
devpod provider set-options podman PODMAN_MACHINE_NAME=my-machine
```

If not specified, the first found Machine will be automatically used.

## Resource Configuration

### Recommended Settings by Use Case

**Lightweight Development (Frontend, etc.):**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=2 \
  PODMAN_MACHINE_MEMORY=2048 \
  PODMAN_MACHINE_DISK_SIZE=50
```

**Standard Development (Backend, Full-stack):**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=4 \
  PODMAN_MACHINE_MEMORY=4096 \
  PODMAN_MACHINE_DISK_SIZE=100
```

**Heavy Development (Build, Multi-service):**
```bash
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=8 \
  PODMAN_MACHINE_MEMORY=8192 \
  PODMAN_MACHINE_DISK_SIZE=200
```

### How to Change Resources

There are two ways to change resource configuration of existing Podman Machine:

#### Method 1: Non-destructive In-place Update (Recommended)

Update resources while preserving the existing Machine. No data loss.

**Automatic Update**:
```bash
# Enable automatic updates
devpod provider set-options podman PODMAN_MACHINE_AUTO_RESOURCE_UPDATE=true

# Change resource configuration
devpod provider set-options podman \
  PODMAN_MACHINE_CPUS=4 \
  PODMAN_MACHINE_MEMORY=8192

# Resources will be automatically updated on next devpod up
devpod up <your-repo> --provider podman
```

**Manual Update**:
```bash
# Stop Machine
podman machine stop

# Update resources (only desired items)
podman machine set <machine-name> --cpus 4
podman machine set <machine-name> --memory 8192
podman machine set <machine-name> --disk-size 150  # Can only increase

# Start Machine
podman machine start
```

**Note**: Disk size can only be increased, not decreased.

#### Method 2: Machine Recreation (Destructive)

Create a completely new Machine. All data will be deleted.

```bash
# 1. Set options
devpod provider set-options podman PODMAN_MACHINE_MEMORY=8192

# 2. Delete existing Machine (⚠️ Data loss)
podman machine stop
podman machine rm

# 3. Create new Machine (auto-created on next devpod up)
devpod up <your-repo> --provider podman
```

**Note**: If automatic creation (`AUTO_INIT=true`) is enabled, a new Machine with the new configuration will be automatically created on the next `devpod up` after Machine deletion.

## Troubleshooting

### "No Podman Machine found" Error

**Cause**: Podman Machine has not been created (macOS)

**Solution 1 - Manual Creation**:
```bash
podman machine init
podman machine start
```

**Solution 2 - Enable Auto-creation**:
```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
```

### "Podman Machine is not running" Error

**Cause**: Machine is stopped

**Solution 1 - Manual Start**:
```bash
podman machine start
```

**Solution 2 - Enable Auto-start (Enabled by Default)**:
```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_START=true
```

### "Machine start timed out" Error

**Cause**: Machine startup is taking longer than expected

**Solution**:
```bash
# Extend timeout to 120 seconds
devpod provider set-options podman PODMAN_MACHINE_START_TIMEOUT=120
```

**Diagnosis**:
```bash
# Check Machine status
podman machine list
podman machine inspect <machine-name>

# Manually start and check logs
podman machine start <machine-name>
```

### Machine Creation/Startup Failure

**Solution**:
```bash
# Delete existing Machine and recreate
podman machine stop
podman machine rm

# Recreate manually
podman machine init
podman machine start

# Or let auto-creation handle it
devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true
devpod up <your-repo> --provider podman
```

### Managing Multiple Machines

When using multiple Podman Machines:

```bash
# List Machines
podman machine list

# Specify a particular Machine
devpod provider set-options podman PODMAN_MACHINE_NAME=my-machine

# Revert to default (auto-detection)
devpod provider set-options podman PODMAN_MACHINE_NAME=""
```

### Resource Configuration Mismatch Warning

**Cause**: Existing Machine differs from requested resource configuration

**Symptom**: Warning message displayed on startup

**Solution 1 - Enable Auto-update (Recommended)**:
```bash
devpod provider set-options podman PODMAN_MACHINE_AUTO_RESOURCE_UPDATE=true
```

**Solution 2 - Manual Update**:
Run the `podman machine set` commands shown in the warning message.

**Solution 3 - Keep Current Configuration**:
Ignore the warning and continue using the existing Machine configuration.

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## References

- [DevPod Official Site](https://devpod.sh/)
- [DevPod Provider Development Guide](https://devpod.sh/docs/developing-providers/quickstart)
- [Podman Official Site](https://podman.io/)

## Development

Contributions to this project are welcome. See [CLAUDE.md](CLAUDE.md) for details.

When adding new features or platform support, please create a GitHub Issue and follow issue-driven development.
