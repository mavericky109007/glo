#!/usr/bin/env python3
"""
Comprehensive OTA Test Suite
Tests various OTA scenarios with different MSISDN formats
"""

import sys
import time
from enhanced_ota_client import EnhancedOTAClient

class ComprehensiveOTATest:
    """Comprehensive OTA testing suite"""
    
    def __init__(self):
        self.client = EnhancedOTAClient()
        self.test_results = []
    
    def run_msisdn_validation_tests(self):
        """Test MSISDN validation with various formats"""
        print("=== MSISDN Validation Tests ===")
        
        test_cases = [
            ("16461099282", True, "US number"),
            ("447700900123", True, "UK number"),
            ("491701234567", True, "German number"),
            ("+16461099282", True, "US number with +"),
            ("0461099282", True, "National format"),
            ("123", False, "Too short"),
            ("123456789012345678", False, "Too long"),
            ("001010123456789", True, "Test network"),
        ]
        
        for msisdn, expected, description in test_cases:
            result = self.client.validate_msisdn(msisdn)
            status = "✅" if result == expected else "❌"
            print(f"{status} {description}: {msisdn} -> {result}")
            self.test_results.append((f"MSISDN validation: {description}", result == expected))
    
    def run_connectivity_tests(self):
        """Test SMPP connectivity"""
        print("\n=== Connectivity Tests ===")
        
        # Test connection
        if self.client.connect():
            print("✅ SMPP connection successful")
            self.test_results.append(("SMPP connection", True))
            
            # Test disconnect
            self.client.disconnect()
            print("✅ SMPP disconnection successful")
            self.test_results.append(("SMPP disconnection", True))
        else:
            print("❌ SMPP connection failed")
            self.test_results.append(("SMPP connection", False))
    
    def run_ota_message_tests(self, test_msisdn: str):
        """Test OTA message sending"""
        print(f"\n=== OTA Message Tests (MSISDN: {test_msisdn}) ===")
        
        if not self.client.connect():
            print("❌ Cannot connect to SMPP server")
            return
        
        try:
            # Test message sending
            result = self.client.send_test_message(test_msisdn)
            status = "✅" if result else "❌"
            print(f"{status} Test message sent")
            self.test_results.append(("OTA test message", result))
            
            time.sleep(1)  # Brief delay between messages
            
            # Test applet installation (with dummy data)
            dummy_aid = "D07002CA44900101"
            dummy_cap = b'\x00\x01\x02\x03DUMMY_CAP_DATA'
            
            # Create temporary CAP file for testing
            with open('/tmp/test_applet.cap', 'wb') as f:
                f.write(dummy_cap)
            
            result = self.client.install_applet(test_msisdn, dummy_aid, '/tmp/test_applet.cap')
            status = "✅" if result else "❌"
            print(f"{status} Applet installation message sent")
            self.test_results.append(("OTA install message", result))
            
            time.sleep(1)
            
            # Test applet deletion
            result = self.client.delete_applet(test_msisdn, dummy_aid)
            status = "✅" if result else "❌"
            print(f"{status} Applet deletion message sent")
            self.test_results.append(("OTA delete message", result))
            
        finally:
            self.client.disconnect()
    
    def run_international_tests(self):
        """Test international MSISDN handling"""
        print("\n=== International MSISDN Tests ===")
        
        international_numbers = [
            ("16461099282", "US"),
            ("447700900123", "UK"),
            ("491701234567", "Germany"),
            ("33123456789", "France"),
            ("39123456789", "Italy"),
        ]
        
        for msisdn, country in international_numbers:
            normalized = self.client.normalize_msisdn(msisdn)
            valid = self.client.validate_msisdn(msisdn)
            status = "✅" if valid else "❌"
            print(f"{status} {country}: {msisdn} -> {normalized}")
            self.test_results.append((f"International {country}", valid))
    
    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*50)
        print("TEST SUMMARY")
        print("="*50)
        
        passed = sum(1 for _, result in self.test_results if result)
        total = len(self.test_results)
        
        print(f"Total tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Success rate: {passed/total*100:.1f}%")
        
        print("\nDetailed Results:")
        for test_name, result in self.test_results:
            status = "✅" if result else "❌"
            print(f"{status} {test_name}")
        
        return passed == total

def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python3 comprehensive_ota_test.py <test_msisdn>")
        print("Example: python3 comprehensive_ota_test.py 16461099282")
        sys.exit(1)
    
    test_msisdn = sys.argv[1]
    
    print("🧪 Starting Comprehensive OTA Test Suite")
    print(f"Test MSISDN: {test_msisdn}")
    print("="*50)
    
    test_suite = ComprehensiveOTATest()
    
    # Run all test categories
    test_suite.run_msisdn_validation_tests()
    test_suite.run_connectivity_tests()
    test_suite.run_ota_message_tests(test_msisdn)
    test_suite.run_international_tests()
    
    # Print summary and exit with appropriate code
    success = test_suite.print_summary()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
