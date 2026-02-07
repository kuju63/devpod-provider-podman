#!/bin/bash
# Test script for resource configuration mismatch detection
# This tests the logic added in Phase 3 for warning users about resource config changes

set -e

echo "=== Phase 3 Resource Configuration Mismatch Detection Test ==="
echo ""

# Helper function to test mismatch detection
test_mismatch_detection() {
  local test_name="$1"
  local machine_info="$2"
  local desired_cpus="$3"
  local desired_memory="$4"
  local desired_disk="$5"
  local desired_rootful="$6"
  local should_mismatch="$7"

  echo "Testing: $test_name"

  # Parse current machine configuration
  CURRENT_CPUS=$(echo "$machine_info" | grep -o '"CPUs": *[0-9]*' | awk '{print $2}')
  CURRENT_MEMORY=$(echo "$machine_info" | grep -o '"Memory": *[0-9]*' | awk '{print $2}')
  CURRENT_DISK=$(echo "$machine_info" | grep -o '"DiskSize": *[0-9]*' | awk '{print $2}')
  CURRENT_ROOTFUL=$(echo "$machine_info" | grep -o '"Rootful": *[a-z]*' | awk '{print $2}')

  # Normalize rootful values for comparison
  NORM_CURRENT_ROOTFUL="false"
  if [ "$CURRENT_ROOTFUL" = "true" ] || [ "$CURRENT_ROOTFUL" = "1" ]; then
    NORM_CURRENT_ROOTFUL="true"
  fi

  # Detect mismatches
  MISMATCHES=""
  if [ "$CURRENT_CPUS" != "$desired_cpus" ]; then
    MISMATCHES="${MISMATCHES}  • CPUs: Current=${CURRENT_CPUS}, Desired=${desired_cpus}\n"
  fi
  if [ "$CURRENT_MEMORY" != "$desired_memory" ]; then
    MISMATCHES="${MISMATCHES}  • Memory: Current=${CURRENT_MEMORY}MB, Desired=${desired_memory}MB\n"
  fi
  if [ "$CURRENT_DISK" != "$desired_disk" ]; then
    MISMATCHES="${MISMATCHES}  • Disk Size: Current=${CURRENT_DISK}GB, Desired=${desired_disk}GB\n"
  fi
  if [ "$NORM_CURRENT_ROOTFUL" != "$desired_rootful" ]; then
    MISMATCHES="${MISMATCHES}  • Rootful Mode: Current=${NORM_CURRENT_ROOTFUL}, Desired=${desired_rootful}\n"
  fi

  # Verify result
  if [ -n "$MISMATCHES" ] && [ "$should_mismatch" = "true" ]; then
    echo "✓ $test_name: Correctly detected mismatch"
    echo -e "$MISMATCHES" | sed 's/^/  /'
    return 0
  elif [ -z "$MISMATCHES" ] && [ "$should_mismatch" = "false" ]; then
    echo "✓ $test_name: Correctly detected no mismatch"
    return 0
  else
    echo "✗ $test_name: FAILED"
    if [ "$should_mismatch" = "true" ]; then
      echo "  Expected: mismatch detected"
      echo "  Got: no mismatch"
    else
      echo "  Expected: no mismatch"
      echo "  Got: mismatch detected"
    fi
    return 1
  fi
}

echo ""
echo "--- Test 1: CPU mismatch detection ---"
MACHINE_INFO1='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 100
  },
  "Rootful": false
}'
test_mismatch_detection "CPU mismatch (2 vs 8)" "$MACHINE_INFO1" "8" "2048" "100" "false" "true"

echo ""
echo "--- Test 2: Memory mismatch detection ---"
MACHINE_INFO2='{
  "Resources": {
    "CPUs": 4,
    "Memory": 2048,
    "DiskSize": 100
  },
  "Rootful": false
}'
test_mismatch_detection "Memory mismatch (2048 vs 4096)" "$MACHINE_INFO2" "4" "4096" "100" "false" "true"

echo ""
echo "--- Test 3: Disk size mismatch detection ---"
MACHINE_INFO3='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 50
  },
  "Rootful": false
}'
test_mismatch_detection "Disk size mismatch (50 vs 100)" "$MACHINE_INFO3" "2" "2048" "100" "false" "true"

echo ""
echo "--- Test 4: Rootful mode mismatch detection ---"
MACHINE_INFO4='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 100
  },
  "Rootful": true
}'
test_mismatch_detection "Rootful mismatch (true vs false)" "$MACHINE_INFO4" "2" "2048" "100" "false" "true"

echo ""
echo "--- Test 5: No mismatch when values match ---"
MACHINE_INFO5='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 100
  },
  "Rootful": false
}'
test_mismatch_detection "No mismatch (all match)" "$MACHINE_INFO5" "2" "2048" "100" "false" "false"

echo ""
echo "--- Test 6: Multiple mismatches ---"
MACHINE_INFO6='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 50
  },
  "Rootful": false
}'
test_mismatch_detection "Multiple mismatches (CPU, Disk, Memory)" "$MACHINE_INFO6" "4" "4096" "100" "false" "true"

echo ""
echo "--- Test 7: Rootful normalization (true vs true) ---"
MACHINE_INFO7='{
  "Resources": {
    "CPUs": 2,
    "Memory": 2048,
    "DiskSize": 100
  },
  "Rootful": true
}'
test_mismatch_detection "Rootful true (no mismatch)" "$MACHINE_INFO7" "2" "2048" "100" "true" "false"

echo ""
echo "=== All mismatch detection tests completed successfully! ==="
