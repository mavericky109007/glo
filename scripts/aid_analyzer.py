#!/usr/bin/env python3
"""
CAP File AID Extractor
Extracts Package AID and Applet AID from Java Card CAP files
"""

import zipfile
import struct
import os
import sys
from typing import Dict, List, Tuple, Optional

class CAPFileAnalyzer:
    """Analyzes CAP files to extract Package and Applet AIDs"""

    def __init__(self, cap_file_path: str):
        self.cap_file_path = cap_file_path
        self.package_aid = None
        self.applet_aids = []
        self.package_info = {}

    def extract_aids_from_cap(self) -> Dict:
        """Extract AIDs from CAP file"""
        try:
            with zipfile.ZipFile(self.cap_file_path, 'r') as cap_zip:
                # Extract Header.cap for package information
                if 'Header.cap' in cap_zip.namelist():
                    header_data = cap_zip.read('Header.cap')
                    self.package_aid = self._parse_header_component(header_data)

                # Extract Applet.cap for applet information
                if 'Applet.cap' in cap_zip.namelist():
                    applet_data = cap_zip.read('Applet.cap')
                    self.applet_aids = self._parse_applet_component(applet_data)

                # Extract MANIFEST.MF for additional info
                if 'META-INF/MANIFEST.MF' in cap_zip.namelist():
                    manifest_data = cap_zip.read('META-INF/MANIFEST.MF').decode('utf-8')
                    self._parse_manifest(manifest_data)

        except FileNotFoundError:
             print(f"Error: CAP file not found at {self.cap_file_path}")
             return {}
        except zipfile.BadZipFile:
             print(f"Error: {self.cap_file_path} is not a valid zip file (or CAP file)")
             return {}
        except Exception as e:
            print(f"Error analyzing CAP file: {e}")
            return {}

        return {
            'package_aid': self.package_aid,
            'applet_aids': self.applet_aids,
            'package_info': self.package_info
        }

    def _parse_header_component(self, header_data: bytes) -> Optional[str]:
        """Parse Header.cap component to extract package AID"""
        try:
            # Header component structure:
            # tag (1 byte) + size (2 bytes) + magic (4 bytes) +
            # minor_version (1) + major_version (1) + flags (1) +
            # package info...

            offset = 0
            # Check if data is long enough for basic header
            if len(header_data) < 9:
                 print("Header data too short.")
                 return None

            tag = header_data[offset]
            offset += 1

            size = struct.unpack('>H', header_data[offset:offset+2])[0]
            offset += 2

            magic = struct.unpack('>I', header_data[offset:offset+4])[0]
            offset += 4

            # Skip version info
            offset += 3

            # Package info
            if offset >= len(header_data):
                 print("Header data ended before package info.")
                 return None

            package_name_length = header_data[offset]
            offset += 1

            if package_name_length > 0:
                if offset + package_name_length > len(header_data):
                     print("Header data too short for package AID.")
                     return None
                package_aid_bytes = header_data[offset:offset+package_name_length]
                package_aid = ''.join([f'{b:02X}' for b in package_aid_bytes])
                return package_aid

        except Exception as e:
            print(f"Error parsing header component: {e}")

        return None

    def _parse_applet_component(self, applet_data: bytes) -> List[str]:
        """Parse Applet.cap component to extract applet AIDs"""
        applet_aids = []
        try:
            offset = 0
            # Check if data is long enough for basic applet header
            if len(applet_data) < 4:
                 print("Applet data too short.")
                 return []

            tag = applet_data[offset]
            offset += 1

            size = struct.unpack('>H', applet_data[offset:offset+2])[0]
            offset += 2

            if offset >= len(applet_data):
                 print("Applet data ended before applet count.")
                 return []

            count = applet_data[offset]
            offset += 1

            for i in range(count):
                if offset >= len(applet_data):
                     print(f"Applet data ended unexpectedly while parsing applet {i+1}.")
                     break

                aid_length = applet_data[offset]
                offset += 1

                if aid_length > 0:
                    if offset + aid_length > len(applet_data):
                         print(f"Applet data too short for AID {i+1}.")
                         break
                    aid_bytes = applet_data[offset:offset+aid_length]
                    aid = ''.join([f'{b:02X}' for b in aid_bytes])
                    applet_aids.append(aid)
                    offset += aid_length

                # Skip install_method_offset (2 bytes)
                if offset + 2 > len(applet_data):
                     print(f"Applet data too short for install method offset for applet {i+1}.")
                     break
                offset += 2

        except Exception as e:
            print(f"Error parsing applet component: {e}")

        return applet_aids

    def _parse_manifest(self, manifest_content: str):
        """Parse MANIFEST.MF for additional package information"""
        for line in manifest_content.split('\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip()

                if key in ['Package-AID', 'Applet-AID', 'Package-Name', 'Package-Version']:
                    self.package_info[key] = value

def analyze_cap_file(cap_file_path: str):
    """Analyze a CAP file and print AID information"""
    analyzer = CAPFileAnalyzer(cap_file_path)
    results = analyzer.extract_aids_from_cap()

    print(f"=== CAP File Analysis: {os.path.basename(cap_file_path)} ===")
    print(f"Package AID: {results.get('package_aid', 'Not found')}")
    print(f"Applet AIDs: {results.get('applet_aids', [])}")
    print(f"Additional Info (from MANIFEST.MF): {results.get('package_info', {})}")
    print()

    return results

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 aid_analyzer.py <path_to_cap_file>")
        sys.exit(1)

    cap_file_path = sys.argv[1]
    analyze_cap_file(cap_file_path)
