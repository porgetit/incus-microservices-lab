#!/bin/bash
# validate-infrastructure.sh - Comprehensive validation of the Incus microservices lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Functions
print_header() {
    echo -e "\n${BLUE}=========================================="
    echo "  $1"
    echo "==========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((TESTS_WARNING++))
    ((TESTS_TOTAL++))
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_separator() {
    echo -e "${BLUE}-------------------------------------------${NC}"
}

# Expected containers and their profiles
declare -A EXPECTED_CONTAINERS
EXPECTED_CONTAINERS[ctl]="ctl"
EXPECTED_CONTAINERS[api]="api"
EXPECTED_CONTAINERS[core]="core"
EXPECTED_CONTAINERS[db]="db"
EXPECTED_CONTAINERS[mon]="mon"
EXPECTED_CONTAINERS[ceph]="ceph"

# Expected volumes
EXPECTED_VOLUMES=(
    "postgres-data"
    "prometheus-data"
    "grafana-data"
    "ceph-data"
    "app-data"
)

# Volume mount mappings
declare -A VOLUME_MOUNTS
VOLUME_MOUNTS[db]="postgres-data:/var/lib/postgresql"
VOLUME_MOUNTS[mon]="prometheus-data:/prometheus grafana-data:/var/lib/grafana"
VOLUME_MOUNTS[api]="app-data:/app/data"
VOLUME_MOUNTS[core]="app-data:/app/data"
VOLUME_MOUNTS[ceph]="ceph-data:/var/lib/ceph"

# Expected services in each container
declare -A EXPECTED_SERVICES
EXPECTED_SERVICES[ctl]="systemd"
EXPECTED_SERVICES[api]="systemd"
EXPECTED_SERVICES[core]="systemd"
EXPECTED_SERVICES[db]="postgresql"
EXPECTED_SERVICES[mon]="systemd"
EXPECTED_SERVICES[ceph]="systemd"

# Start validation
echo -e "${BLUE}╔════════════════════════════════════════╗"
echo "║  INCUS MICROSERVICES LAB VALIDATION   ║"
echo "║  $(date '+%Y-%m-%d %H:%M:%S')                 ║"
echo -e "╚════════════════════════════════════════╝${NC}\n"

# ============================================
# 1. CHECK INCUS DAEMON
# ============================================
print_header "1. CHECKING INCUS DAEMON"

if sudo systemctl is-active --quiet incus; then
    print_success "Incus daemon is running"
else
    print_fail "Incus daemon is NOT running"
    echo "  Attempting to start..."
    sudo systemctl start incus
    sleep 3
    if sudo systemctl is-active --quiet incus; then
        print_success "Incus daemon started successfully"
    else
        print_fail "Failed to start Incus daemon"
    fi
fi

INCUS_VERSION=$(incus --version)
print_info "Incus version: $INCUS_VERSION"

# ============================================
# 2. CHECK NETWORKS
# ============================================
print_header "2. CHECKING NETWORKS"

# Check incusbr0
if sudo incus network show incusbr0 >/dev/null 2>&1; then
    MANAGED=$(sudo incus network show incusbr0 | grep -E '^\s*managed:' | awk '{print $2}')
    if [ "$MANAGED" = "true" ]; then
        print_success "incusbr0 exists and is MANAGED"
        INCUSBR0_IP=$(sudo incus network show incusbr0 | grep -E '^\s*ipv4.address:' | awk '{print $2}')
        print_info "  IP address: $INCUSBR0_IP"
    else
        print_fail "incusbr0 exists but is NOT managed"
    fi
else
    print_fail "incusbr0 network does not exist"
fi

# Check lab-net
if sudo incus network show lab-net >/dev/null 2>&1; then
    TYPE=$(sudo incus network show lab-net | grep -E '^\s*type:' | awk '{print $2}')
    if [ "$TYPE" = "ovn" ]; then
        print_success "lab-net OVN network exists"
        LAB_NET_IP=$(sudo incus network show lab-net | grep -E '^\s*ipv4.address:' | awk '{print $2}')
        print_info "  IP address: $LAB_NET_IP"
    else
        print_fail "lab-net exists but type is not OVN (type: $TYPE)"
    fi
else
    print_fail "lab-net network does not exist"
fi

print_separator
sudo incus network list
print_separator

# ============================================
# 3. CHECK CONTAINERS
# ============================================
print_header "3. CHECKING CONTAINERS"

for container in "${!EXPECTED_CONTAINERS[@]}"; do
    print_info "Checking container: $container"
    
    # Check if container exists
    if sudo incus info "$container" >/dev/null 2>&1; then
        # Get container status
        STATUS=$(sudo incus list | grep -E "^\|\s+$container\s+" | awk '{print $6}')
        
        if [ "$STATUS" = "RUNNING" ]; then
            print_success "  ✓ Container '$container' is RUNNING"
        else
            print_fail "  ✗ Container '$container' is $STATUS (expected: RUNNING)"
        fi
        
        # Check IP address
        IP=$(sudo incus list | grep -E "^\|\s+$container\s+" | awk '{print $4}' | head -1)
        if [ ! -z "$IP" ] && [ "$IP" != "-" ]; then
            print_info "  IP address: $IP"
        else
            print_warning "  No IP address assigned"
        fi
    else
        print_fail "  ✗ Container '$container' does not exist"
    fi
done

print_separator
echo "Container Status Summary:"
sudo incus list
print_separator

# ============================================
# 4. CHECK VOLUMES
# ============================================
print_header "4. CHECKING STORAGE VOLUMES"

for volume in "${EXPECTED_VOLUMES[@]}"; do
    if sudo incus storage volume show default "$volume" >/dev/null 2>&1; then
        print_success "Volume '$volume' exists"
    else
        print_fail "Volume '$volume' does not exist"
    fi
done

print_separator
echo "Storage Volume List:"
sudo incus storage volume list
print_separator

# ============================================
# 5. CHECK VOLUME MOUNTS
# ============================================
print_header "5. CHECKING VOLUME MOUNTS IN CONTAINERS"

for container in "${!VOLUME_MOUNTS[@]}"; do
    print_info "Checking mounts for container: $container"
    
    if ! sudo incus info "$container" >/dev/null 2>&1; then
        print_warning "  Container '$container' does not exist, skipping"
        continue
    fi
    
    if ! sudo incus info "$container" | grep -q "RUNNING"; then
        print_warning "  Container '$container' is not running, skipping mount check"
        continue
    fi
    
    MOUNTS=${VOLUME_MOUNTS[$container]}
    for mount in $MOUNTS; do
        VOLUME=$(echo $mount | cut -d: -f1)
        MOUNT_PATH=$(echo $mount | cut -d: -f2)
        
        # Check if volume is attached to container
        if sudo incus config show "$container" | grep -q "source: $VOLUME"; then
            print_success "  ✓ Volume '$VOLUME' is attached"
            
            # Try to access the mount point inside the container
            if sudo incus exec "$container" -- test -d "$MOUNT_PATH" 2>/dev/null; then
                print_success "    ✓ Mount path '$MOUNT_PATH' is accessible"
                
                # Check if mount is writable
                if sudo incus exec "$container" -- touch "$MOUNT_PATH/.test" 2>/dev/null; then
                    sudo incus exec "$container" -- rm "$MOUNT_PATH/.test" 2>/dev/null
                    print_success "    ✓ Mount path is WRITABLE"
                else
                    print_warning "    ⚠️  Mount path is READ-ONLY"
                fi
            else
                print_fail "    ✗ Mount path '$MOUNT_PATH' is NOT accessible"
            fi
        else
            print_fail "  ✗ Volume '$VOLUME' is NOT attached to container"
        fi
    done
done

# ============================================
# 6. CHECK CONNECTIVITY BETWEEN CONTAINERS
# ============================================
print_header "6. CHECKING CONTAINER CONNECTIVITY"

# Get IPs of running containers
declare -A CONTAINER_IPS
for container in "${!EXPECTED_CONTAINERS[@]}"; do
    if sudo incus info "$container" >/dev/null 2>&1; then
        if sudo incus exec "$container" -- test -f /etc/hostname 2>/dev/null; then
            IP=$(sudo incus exec "$container" -- hostname -I | awk '{print $1}' 2>/dev/null || echo "")
            if [ ! -z "$IP" ]; then
                CONTAINER_IPS[$container]=$IP
            fi
        fi
    fi
done

# Test ping between containers
print_info "Testing ping connectivity between containers..."
CONTAINERS_ARRAY=(${!CONTAINER_IPS[@]})
PING_TESTS=0
PING_PASSED=0

for i in "${!CONTAINERS_ARRAY[@]}"; do
    SOURCE_CONTAINER=${CONTAINERS_ARRAY[$i]}
    SOURCE_IP=${CONTAINER_IPS[$SOURCE_CONTAINER]}
    
    for j in "${!CONTAINERS_ARRAY[@]}"; do
        if [ "$i" -ne "$j" ]; then
            TARGET_CONTAINER=${CONTAINERS_ARRAY[$j]}
            TARGET_IP=${CONTAINER_IPS[$TARGET_CONTAINER]}
            
            ((PING_TESTS++))
            
            if sudo incus exec "$SOURCE_CONTAINER" -- ping -c 1 "$TARGET_IP" >/dev/null 2>&1; then
                print_success "  $SOURCE_CONTAINER → $TARGET_CONTAINER ($TARGET_IP)"
                ((PING_PASSED++))
            else
                print_fail "  $SOURCE_CONTAINER → $TARGET_CONTAINER ($TARGET_IP)"
            fi
        fi
    done
done

print_info "Ping connectivity: $PING_PASSED/$PING_TESTS successful"

# ============================================
# 7. CHECK CONTAINER-SPECIFIC SERVICES
# ============================================
print_header "7. CHECKING CONTAINER SERVICES"

# Check db-postgres
print_info "Checking database (db) container..."
if sudo incus info "db" >/dev/null 2>&1; then
    if sudo incus exec "db" -- systemctl is-active --quiet postgresql 2>/dev/null; then
        print_success "PostgreSQL is running on db container"
        
        # Try to connect
        if sudo incus exec "db" -- psql --version >/dev/null 2>&1; then
            print_success "PostgreSQL client is available"
        fi
    else
        print_warning "PostgreSQL is not running on db container"
    fi
fi

# Check mon (monitoring)
print_info "Checking monitoring (mon) container..."
if sudo incus info "mon" >/dev/null 2>&1; then
    # Check if prometheus could be running
    if sudo incus exec "mon" -- test -d /prometheus 2>/dev/null; then
        print_success "Prometheus data directory exists"
    else
        print_warning "Prometheus data directory not found"
    fi
    
    if sudo incus exec "mon" -- test -d /var/lib/grafana 2>/dev/null; then
        print_success "Grafana data directory exists"
    else
        print_warning "Grafana data directory not found"
    fi
fi

# Check ceph
print_info "Checking Ceph (ceph) container..."
if sudo incus info "ceph" >/dev/null 2>&1; then
    if sudo incus exec "ceph" -- test -d /var/lib/ceph 2>/dev/null; then
        print_success "Ceph data directory exists"
    else
        print_warning "Ceph data directory not found"
    fi
fi

# ============================================
# 8. CHECK SYSTEM RESOURCES
# ============================================
print_header "8. CHECKING SYSTEM RESOURCES"

# CPU and Memory
TOTAL_CPUS=$(nproc)
AVAILABLE_MEMORY=$(free -h | grep Mem | awk '{print $2}')
USED_MEMORY=$(free -h | grep Mem | awk '{print $3}')

print_info "Host System Resources:"
echo "  Total CPUs: $TOTAL_CPUS"
echo "  Total Memory: $AVAILABLE_MEMORY"
echo "  Used Memory: $USED_MEMORY"

# Incus resource usage
print_info "Container Resource Limits:"
for container in "${!EXPECTED_CONTAINERS[@]}"; do
    if sudo incus info "$container" >/dev/null 2>&1; then
        CPU=$(sudo incus profile show "${EXPECTED_CONTAINERS[$container]}" | grep 'limits.cpu' | awk '{print $2}')
        MEMORY=$(sudo incus profile show "${EXPECTED_CONTAINERS[$container]}" | grep 'limits.memory' | awk '{print $2}')
        echo "  $container: CPU=$CPU, Memory=$MEMORY"
    fi
done

# ============================================
# 9. CHECK STORAGE
# ============================================
print_header "9. CHECKING STORAGE"

STORAGE_POOL=$(sudo incus storage list | grep "default" | awk '{print $2}')
if [ ! -z "$STORAGE_POOL" ]; then
    print_success "Default storage pool exists: $STORAGE_POOL"
    
    POOL_DRIVER=$(sudo incus storage show default | grep 'driver:' | awk '{print $2}')
    print_info "  Driver: $POOL_DRIVER"
fi

print_separator
echo "Storage Pools:"
sudo incus storage list
print_separator

# ============================================
# 10. CHECK OVN/OVS STATUS
# ============================================
print_header "10. CHECKING OVN/OVS STATUS"

# Check OVN services
if sudo systemctl is-active --quiet ovn-central; then
    print_success "OVN Central is running"
else
    print_fail "OVN Central is NOT running"
fi

if sudo systemctl is-active --quiet ovn-host; then
    print_success "OVN Host is running"
else
    print_fail "OVN Host is NOT running"
fi

# Check OVS
if sudo systemctl is-active --quiet openvswitch-switch; then
    print_success "Open vSwitch is running"
else
    print_fail "Open vSwitch is NOT running"
fi

# Check Incus OVN connection
OVN_CONN=$(sudo incus config get network.ovn.northbound_connection 2>/dev/null || echo "NOT SET")
if [ "$OVN_CONN" != "NOT SET" ]; then
    print_success "Incus is connected to OVN: $OVN_CONN"
else
    print_fail "Incus is NOT connected to OVN"
fi

# ============================================
# 11. NETWORK DIAGNOSTICS
# ============================================
print_header "11. NETWORK DIAGNOSTICS"

print_info "Testing container gateway connectivity..."
for container in "${!CONTAINER_IPS[@]}"; do
    CONTAINER_IP=${CONTAINER_IPS[$container]}
    
    # Get gateway
    GATEWAY=$(sudo incus exec "$container" -- ip route | grep default | awk '{print $3}')
    
    if [ ! -z "$GATEWAY" ]; then
        if sudo incus exec "$container" -- ping -c 1 "$GATEWAY" >/dev/null 2>&1; then
            print_success "  $container can reach gateway ($GATEWAY)"
        else
            print_fail "  $container cannot reach gateway ($GATEWAY)"
        fi
    else
        print_warning "  $container has no default gateway"
    fi
done

# ============================================
# 12. VOLUME DATA PERSISTENCE CHECK
# ============================================
print_header "12. CHECKING VOLUME DATA PERSISTENCE"

# Create test files on writable volumes
for container in "${!VOLUME_MOUNTS[@]}"; do
    if ! sudo incus info "$container" >/dev/null 2>&1; then
        continue
    fi
    
    if ! sudo incus exec "$container" -- test -f /etc/hostname 2>/dev/null; then
        continue
    fi
    
    MOUNTS=${VOLUME_MOUNTS[$container]}
    for mount in $MOUNTS; do
        MOUNT_PATH=$(echo $mount | cut -d: -f2)
        
        TEST_FILE="$MOUNT_PATH/.persistence-test"
        
        # Try to create and delete test file
        if sudo incus exec "$container" -- touch "$TEST_FILE" 2>/dev/null; then
            if sudo incus exec "$container" -- test -f "$TEST_FILE" 2>/dev/null; then
                if sudo incus exec "$container" -- rm "$TEST_FILE" 2>/dev/null; then
                    print_success "  Volume persistence test PASSED on $container:$MOUNT_PATH"
                else
                    print_warning "  Could not clean up test file"
                fi
            else
                print_fail "  Test file not found after creation"
            fi
        else
            print_warning "  Could not create test file on $MOUNT_PATH"
        fi
    done
done

# ============================================
# SUMMARY
# ============================================
print_header "VALIDATION SUMMARY"

echo "Tests Executed:  $TESTS_TOTAL"
echo -e "Tests Passed:    ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:    ${RED}$TESTS_FAILED${NC}"
echo -e "Tests Warnings:  ${YELLOW}$TESTS_WARNING${NC}"

PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
echo -e "\nPass Rate: ${GREEN}$PASS_RATE%${NC}"

print_separator

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CRITICAL CHECKS PASSED${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}❌ SOME CHECKS FAILED - REVIEW ABOVE${NC}"
    EXIT_CODE=1
fi

if [ $TESTS_WARNING -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $TESTS_WARNING WARNINGS - REVIEW ABOVE${NC}"
fi

# ============================================
# DETAILED DIAGNOSTICS (Optional)
# ============================================
print_header "QUICK REFERENCE: KEY COMMANDS"

echo "View container details:"
echo "  sudo incus list -c name,state,ipv4,profiles"
echo ""
echo "Enter a container:"
echo "  sudo incus exec <container> -- bash"
echo ""
echo "View container logs:"
echo "  sudo incus info <container>"
echo ""
echo "View network status:"
echo "  sudo incus network show lab-net"
echo ""
echo "View volume status:"
echo "  sudo incus storage volume list"
echo ""
echo "Restart validation:"
echo "  bash validate-infrastructure.sh"
echo ""

echo -e "${BLUE}=========================================="
echo "Validation completed at $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "==========================================${NC}\n"

exit $EXIT_CODE