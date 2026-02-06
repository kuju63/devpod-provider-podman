#!/bin/bash
# Integration test for Phase 2: DevPod Provider Integration
set -e

echo "=== Phase 2 Integration Test ==="
echo ""

# Check prerequisites
if ! command -v devpod &> /dev/null; then
  echo "Error: devpod command not found"
  echo "Please install DevPod: brew install devpod"
  exit 1
fi

if ! command -v podman &> /dev/null; then
  echo "Error: podman command not found"
  echo "Please install Podman: brew install podman"
  exit 1
fi

echo "✓ Prerequisites check passed"
echo ""

# Test 1: Provider registration
echo "Test 1: Provider Registration"
cd "$(dirname "$0")/.."
devpod provider add ./provider.yaml --name podman-phase2-test 2>&1 | grep -E "(Successfully|info|done)" | head -10
echo "✓ Provider registered successfully"
echo ""

# Test 2: Check provider options
echo "Test 2: Provider Options"
devpod provider options podman-phase2-test | grep -E "PODMAN_MACHINE" | wc -l | xargs -I {} echo "✓ Found {} Machine-related options"
echo ""

# Test 3: Set custom options
echo "Test 3: Custom Options Setting"
devpod provider set-options podman-phase2-test \
  -o PODMAN_MACHINE_CPUS=4 \
  -o PODMAN_MACHINE_MEMORY=4096 \
  2>&1 | grep -E "(Successfully|done)" | tail -1
echo "✓ Options set successfully"
echo ""

# Test 4: Verify options
echo "Test 4: Verify Options"
CPUS_VALUE=$(devpod provider options podman-phase2-test | grep PODMAN_MACHINE_CPUS | awk '{print $NF}')
MEMORY_VALUE=$(devpod provider options podman-phase2-test | grep PODMAN_MACHINE_MEMORY | awk '{print $NF}')
echo "  CPU: $CPUS_VALUE (expected: 4)"
echo "  Memory: $MEMORY_VALUE (expected: 4096)"

if [ "$CPUS_VALUE" = "4" ] && [ "$MEMORY_VALUE" = "4096" ]; then
  echo "✓ Option values verified"
else
  echo "✗ Option values mismatch"
  exit 1
fi
echo ""

# Cleanup
echo "Cleanup: Removing test provider"
devpod provider delete podman-phase2-test 2>&1 | grep -E "(Successfully|done)" | tail -1
echo "✓ Cleanup completed"
echo ""

echo "=== All integration tests passed! ==="
