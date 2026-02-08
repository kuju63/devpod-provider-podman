#!/bin/bash
# Test script for Phase 2: Init script validation
set -e

echo "=== Phase 2 Init Script Test ==="
echo ""

# Set test environment variables
export PODMAN_PATH="podman"
export PODMAN_MACHINE_NAME=""
export PODMAN_MACHINE_AUTO_START="true"
export PODMAN_MACHINE_AUTO_INIT="false"
export PODMAN_MACHINE_START_TIMEOUT="60"
export PODMAN_MACHINE_CPUS="2"
export PODMAN_MACHINE_MEMORY="2048"
export PODMAN_MACHINE_DISK_SIZE="100"
export PODMAN_MACHINE_ROOTFUL="false"

# Check if podman command exists
if ! command -v ${PODMAN_PATH} &> /dev/null; then
  >&2 echo "Error: Podman binary not found at '${PODMAN_PATH}'"
  >&2 echo "Please install Podman: brew install podman"
  >&2 echo "Or set PODMAN_PATH option to the correct location."
  exit 1
fi

# Check Podman version
PODMAN_VERSION=$(${PODMAN_PATH} --version | awk '{print $3}')
echo "✓ Found Podman version: ${PODMAN_VERSION}"

# Podman Machine management (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "✓ Detected macOS - testing Machine management..."

  # Resolve machine name
  MACHINE_NAME="${PODMAN_MACHINE_NAME:-}"
  if [ -z "$MACHINE_NAME" ]; then
    MACHINE_NAME=$(${PODMAN_PATH} machine list --format '{{.Name}}' --noheading 2>/dev/null | head -n1 || echo "")
    MACHINE_NAME="${MACHINE_NAME%\*}"  # Remove trailing asterisk from active machine
    if [ -n "$MACHINE_NAME" ]; then
      echo "✓ Auto-detected machine: $MACHINE_NAME"
    fi
  fi

  # Check if machine exists
  if [ -z "$MACHINE_NAME" ]; then
    if [ "${PODMAN_MACHINE_AUTO_INIT:-false}" = "true" ]; then
      echo "Creating new Podman Machine..."
      MACHINE_NAME="devpod-machine"

      INIT_CMD="${PODMAN_PATH} machine init \"$MACHINE_NAME\""
      INIT_CMD="$INIT_CMD --cpus ${PODMAN_MACHINE_CPUS:-2}"
      INIT_CMD="$INIT_CMD --memory ${PODMAN_MACHINE_MEMORY:-2048}"
      INIT_CMD="$INIT_CMD --disk-size ${PODMAN_MACHINE_DISK_SIZE:-100}"

      if [ "${PODMAN_MACHINE_ROOTFUL:-false}" = "true" ]; then
        INIT_CMD="$INIT_CMD --rootful"
      fi

      eval $INIT_CMD
      echo "✓ Machine created successfully: $MACHINE_NAME"
    else
      >&2 echo "Error: No Podman Machine found."
      >&2 echo ""
      >&2 echo "Manual fix:"
      >&2 echo "  podman machine init"
      >&2 echo "  podman machine start"
      >&2 echo ""
      >&2 echo "Or enable auto-init:"
      >&2 echo "  devpod provider set-options podman PODMAN_MACHINE_AUTO_INIT=true"
      exit 1
    fi
  fi

  # Check machine state
  MACHINE_STATE=$(${PODMAN_PATH} machine inspect "$MACHINE_NAME" --format '{{.State}}' 2>/dev/null || echo "unknown")
  echo "✓ Machine '$MACHINE_NAME' state: $MACHINE_STATE"

  if [ "$MACHINE_STATE" != "running" ]; then
    if [ "${PODMAN_MACHINE_AUTO_START:-true}" = "true" ]; then
      echo "Starting Podman Machine '$MACHINE_NAME'..."
      ${PODMAN_PATH} machine start "$MACHINE_NAME"

      # Wait for machine to be ready
      TIMEOUT=${PODMAN_MACHINE_START_TIMEOUT:-60}
      ELAPSED=0
      echo "Waiting for machine to be ready (timeout: ${TIMEOUT}s)..."

      while [ $ELAPSED -lt $TIMEOUT ]; do
        if ${PODMAN_PATH} ps >/dev/null 2>&1; then
          echo "✓ Podman Machine ready after ${ELAPSED}s"
          break
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
      done

      if [ $ELAPSED -ge $TIMEOUT ]; then
        >&2 echo "Error: Machine start timed out after ${TIMEOUT}s"
        >&2 echo ""
        >&2 echo "You can increase the timeout:"
        >&2 echo "  devpod provider set-options podman PODMAN_MACHINE_START_TIMEOUT=120"
        exit 1
      fi
    else
      >&2 echo "Error: Podman Machine '$MACHINE_NAME' is not running."
      >&2 echo ""
      >&2 echo "Manual fix:"
      >&2 echo "  podman machine start $MACHINE_NAME"
      >&2 echo ""
      >&2 echo "Or enable auto-start:"
      >&2 echo "  devpod provider set-options podman PODMAN_MACHINE_AUTO_START=true"
      exit 1
    fi
  else
    echo "✓ Machine is already running."
  fi
else
  echo "✓ Non-macOS environment - skipping Machine management"
fi

# Test podman connectivity
echo "Testing Podman connectivity..."
${PODMAN_PATH} ps >/dev/null 2>&1
if [ $? -ne 0 ]; then
  >&2 echo "Error: Podman is not reachable."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    >&2 echo "This should not happen after machine management."
    >&2 echo "Please check: podman machine list"
  else
    >&2 echo "Please ensure Podman is running properly."
  fi
  exit 1
fi

echo "✓ Podman connectivity test passed"
echo ""
echo "=== All tests passed! ==="
