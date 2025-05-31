#!/usr/bin/env python3
"""
Docker-specific OTA testing script
"""

import sys
import os
import subprocess
import time

def run_command(cmd):
    """Run shell command and return result"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def test_environment():
    """Test Docker environment setup"""
    print("=== Testing Docker Environment ===")
    
    tests = [
        ("MongoDB", "pgrep mongod"),
        ("Open5GS MME", "which open5gs-mmed"),
        ("OsmoMSC", "which osmo-msc"),
        ("OsmoHLR", "which osmo-hlr"),
        ("Python SMPP", "python3 -c 'import smpplib'"),
        ("TUN Interface", "ip link show ogstun"),
    ]
    
    results = []
    for test_name, command in tests:
        success, stdout, stderr = run_command(command)
        status = "✓ PASS" if success else "✗ FAIL"
        print(f"{test_name:<20} {status}")
        results.append(success)
    
    return all(results)

def main():
    print("Docker OTA Testing Environment")
    print("=" * 40)
    
    if test_environment():
        print("\n✓ Environment test passed!")
        print("\nNext steps:")
        print("1. Start network: ./scripts/start-network-docker.sh")
        print("2. Run OTA tests: python3 scripts/enhanced_ota_client.py test 12345678900")
    else:
        print("\n✗ Environment test failed!")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 