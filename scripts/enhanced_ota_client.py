#!/usr/bin/env python3
"""
Enhanced OTA Client - Integrated from ryantheelder/OTAapplet
Combines comprehensive testing with focused OTA operations
"""

import smpplib.gsm
import smpplib.client
import smpplib.consts
import binascii
import sys
import time
import logging
from typing import Optional, List

class EnhancedOTAClient:
    def __init__(self, host='127.0.0.25', port=2755, system_id='ota-test', password='123'):
        """Initialize enhanced OTA client with SMPP connection"""
        self.host = host
        self.port = port
        self.system_id = system_id
        self.password = password
        self.client = None
        self.connected = False
        
        # Setup logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # OTA message templates from ryantheelder's implementation
        self.ota_templates = {
            'install_header': '027100001A0A8281830100',
            'delete_header': '027100001A0A8281830200',
            'response_header': '027100001A0A8281830300'
        }
    
    def connect(self) -> bool:
        """Establish SMPP connection"""
        try:
            self.client = smpplib.client.Client(self.host, self.port, 90)
            self.client.connect()
            self.client.bind_transceiver(system_id=self.system_id, password=self.password)
            self.connected = True
            self.logger.info(f"Connected to SMPP server at {self.host}:{self.port}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to connect: {e}")
            return False
    
    def disconnect(self):
        """Close SMPP connection"""
        if self.client and self.connected:
            self.client.unbind()
            self.client.disconnect()
            self.connected = False
            self.logger.info("Disconnected from SMPP server")
    
    def create_install_apdu(self, applet_aid: str, applet_data: str) -> str:
        """
        Create installation APDU based on ryantheelder's format
        Enhanced with proper CAP file handling
        """
        # Install for Install command
        install_cmd = '80E602001C'  # CLA INS P1 P2 LC
        
        # Application AID length and AID
        aid_len = format(len(applet_aid) // 2, '02X')
        
        # Load file data block length and data
        data_len = format(len(applet_data) // 2, '04X')
        
        # Construct full APDU
        apdu = install_cmd + aid_len + applet_aid + data_len + applet_data
        
        return apdu
    
    def create_delete_apdu(self, applet_aid: str) -> str:
        """Create deletion APDU for applet removal"""
        # Delete command
        delete_cmd = '80E400001C'  # CLA INS P1 P2 LC
        
        # AID length and AID
        aid_len = format(len(applet_aid) // 2, '02X')
        
        # Construct deletion APDU
        apdu = delete_cmd + aid_len + applet_aid
        
        return apdu
    
    def wrap_in_ota_envelope(self, apdu: str, operation: str = 'install') -> str:
        """
        Wrap APDU in OTA SMS envelope
        Based on ETSI TS 131 111 specifications
        """
        # Select appropriate header
        if operation == 'install':
            header = self.ota_templates['install_header']
        elif operation == 'delete':
            header = self.ota_templates['delete_header']
        else:
            header = self.ota_templates['response_header']
        
        # Calculate total length
        total_len = format(len(apdu) // 2, '02X')
        
        # Construct OTA message
        ota_message = header + total_len + apdu
        
        return ota_message
    
    def send_ota_sms(self, destination: str, ota_data: str, source_addr: str = '12345') -> bool:
        """Send OTA SMS message"""
        if not self.connected:
            self.logger.error("Not connected to SMPP server")
            return False
        
        try:
            # Convert hex string to bytes
            message_bytes = binascii.unhexlify(ota_data)
            
            # Send SMS
            pdu = self.client.send_message(
                source_addr_ton=smpplib.consts.ADDR_TON_INTL,
                source_addr_npi=smpplib.consts.ADDR_NPI_ISDN,
                source_addr=source_addr,
                dest_addr_ton=smpplib.consts.ADDR_TON_INTL,
                dest_addr_npi=smpplib.consts.ADDR_NPI_ISDN,
                destination_addr=destination,
                short_message=message_bytes,
                data_coding=smpplib.consts.SMPP_GSMFEAT_UDHI
            )
            
            self.logger.info(f"OTA SMS sent to {destination}, Message ID: {pdu.message_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to send OTA SMS: {e}")
            return False
    
    def install_applet(self, destination: str, applet_aid: str, cap_file_path: str) -> bool:
        """Install applet via OTA SMS"""
        try:
            # Read CAP file
            with open(cap_file_path, 'rb') as f:
                cap_data = f.read().hex().upper()
            
            # Create installation APDU
            install_apdu = self.create_install_apdu(applet_aid, cap_data)
            
            # Wrap in OTA envelope
            ota_message = self.wrap_in_ota_envelope(install_apdu, 'install')
            
            # Send OTA SMS
            return self.send_ota_sms(destination, ota_message)
            
        except Exception as e:
            self.logger.error(f"Failed to install applet: {e}")
            return False
    
    def delete_applet(self, destination: str, applet_aid: str) -> bool:
        """Delete applet via OTA SMS"""
        try:
            # Create deletion APDU
            delete_apdu = self.create_delete_apdu(applet_aid)
            
            # Wrap in OTA envelope
            ota_message = self.wrap_in_ota_envelope(delete_apdu, 'delete')
            
            # Send OTA SMS
            return self.send_ota_sms(destination, ota_message)
            
        except Exception as e:
            self.logger.error(f"Failed to delete applet: {e}")
            return False

def main():
    """Main function for command-line usage"""
    if len(sys.argv) < 3:
        print("Usage: python3 enhanced_ota_client.py <operation> <destination> [applet_aid] [cap_file]")
        print("Operations: install, delete, test")
        sys.exit(1)
    
    operation = sys.argv[1]
    destination = sys.argv[2]
    
    client = EnhancedOTAClient()
    
    try:
        if not client.connect():
            print("Failed to connect to SMPP server")
            sys.exit(1)
        
        if operation == 'install':
            if len(sys.argv) < 5:
                print("Install requires: applet_aid and cap_file")
                sys.exit(1)
            
            applet_aid = sys.argv[3]
            cap_file = sys.argv[4]
            
            if client.install_applet(destination, applet_aid, cap_file):
                print(f"Applet installation initiated for {destination}")
            else:
                print("Failed to install applet")
        
        elif operation == 'delete':
            if len(sys.argv) < 4:
                print("Delete requires: applet_aid")
                sys.exit(1)
            
            applet_aid = sys.argv[3]
            
            if client.delete_applet(destination, applet_aid):
                print(f"Applet deletion initiated for {destination}")
            else:
                print("Failed to delete applet")
        
        elif operation == 'test':
            # Send test SMS
            test_message = "48656C6C6F20576F726C64"  # "Hello World" in hex
            if client.send_ota_sms(destination, test_message):
                print(f"Test message sent to {destination}")
            else:
                print("Failed to send test message")
        
        else:
            print(f"Unknown operation: {operation}")
    
    finally:
        client.disconnect()

if __name__ == "__main__":
    main() 