#!/usr/bin/env python3
"""
Java Card AID Manager
Provides tools to analyze CAP files, generate AIDs, and create project templates.
"""

import zipfile
import struct
import os
import sys
import random
import hashlib
from typing import Dict, List, Tuple, Optional

# --- CAP File Analyzer (from Method 1) ---
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
                 # print("Header data too short.") # Suppress verbose errors for cleaner output
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
                 # print("Header data ended before package info.") # Suppress verbose errors
                 return None

            package_name_length = header_data[offset]
            offset += 1

            if package_name_length > 0:
                if offset + package_name_length > len(header_data):
                     # print("Header data too short for package AID.") # Suppress verbose errors
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
                 # print("Applet data too short.") # Suppress verbose errors
                 return []

            tag = applet_data[offset]
            offset += 1

            size = struct.unpack('>H', applet_data[offset:offset+2])[0]
            offset += 2

            if offset >= len(applet_data):
                 # print("Applet data ended before applet count.") # Suppress verbose errors
                 return []

            count = applet_data[offset]
            offset += 1

            for i in range(count):
                if offset >= len(applet_data):
                     # print(f"Applet data ended unexpectedly while parsing applet {i+1}.") # Suppress verbose errors
                     break

                aid_length = applet_data[offset]
                offset += 1

                if aid_length > 0:
                    if offset + aid_length > len(applet_data):
                         # print(f"Applet data too short for AID {i+1}.") # Suppress verbose errors
                         break
                    aid_bytes = applet_data[offset:offset+aid_length]
                    aid = ''.join([f'{b:02X}' for b in aid_bytes])
                    applet_aids.append(aid)
                    offset += aid_length

                # Skip install_method_offset (2 bytes)
                if offset + 2 > len(applet_data):
                     # print(f"Applet data too short for install method offset for applet {i+1}.") # Suppress verbose errors
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

# --- AID Generator (from Method 2) ---
class AIDGenerator:
    """Generates valid AIDs for Java Card applications"""

    # Standard RID (Resource Identifier) values
    RIDS = {
        'test': 'A000000001',      # Test RID
        'custom': 'A000000151',    # Custom development RID
        'demo': 'A000000062',      # Demo applications RID
        'research': 'A000000087'   # Research RID
    }

    def __init__(self, rid_type: str = 'custom'):
        self.rid = self.RIDS.get(rid_type, self.RIDS['custom'])
        if self.rid not in self.RIDS.values():
             print(f"Warning: Unknown RID type '{rid_type}'. Using default 'custom'.")
             self.rid = self.RIDS['custom']


    def generate_package_aid(self, package_name: str, version: str = '01') -> str:
        """Generate Package AID based on package name"""
        # Create PIX (Proprietary Identifier eXtension) from package name
        # Using MD5 hash of package name for uniqueness, truncated to 5 bytes (10 hex chars)
        package_hash = hashlib.md5(package_name.encode()).hexdigest()[:10]
        # Add version as 1 byte (2 hex chars)
        version_hex = f"{int(version):02X}" if version.isdigit() and 0 <= int(version) <= 255 else '01' # Ensure version is valid hex
        pix = package_hash.upper() + version_hex

        package_aid = self.rid + pix
        # Ensure AID is between 5 and 16 bytes (10 and 32 hex chars)
        if len(package_aid) < 10 or len(package_aid) > 32:
             print(f"Warning: Generated Package AID length ({len(package_aid)//2} bytes) is outside the typical range (5-16 bytes).")

        return package_aid

    def generate_applet_aid(self, package_aid: str, applet_name: str) -> str:
        """Generate Applet AID based on package AID and applet name"""
        # Use package AID as base and add applet-specific suffix
        # Using MD5 hash of applet name for uniqueness, truncated to 2 bytes (4 hex chars)
        applet_hash = hashlib.md5(applet_name.encode()).hexdigest()[:4]
        applet_aid = package_aid + applet_hash.upper()

        # Ensure AID is between 5 and 16 bytes (10 and 32 hex chars)
        if len(applet_aid) < 10 or len(applet_aid) > 32:
             print(f"Warning: Generated Applet AID length ({len(applet_aid)//2} bytes) is outside the typical range (5-16 bytes).")

        return applet_aid

    def generate_project_aids(self, project_info: Dict) -> Dict:
        """Generate complete AID set for a Java Card project"""
        package_name = project_info.get('package_name', 'com.example.default')
        applet_names = project_info.get('applet_names', ['DefaultApplet'])
        version = project_info.get('version', '01')

        package_aid = self.generate_package_aid(package_name, version)

        applet_aids = []
        for applet_name in applet_names:
            applet_aid = self.generate_applet_aid(package_aid, applet_name)
            applet_aids.append({
                'name': applet_name,
                'aid': applet_aid
            })

        return {
            'package_name': package_name,
            'package_aid': package_aid,
            'applets': applet_aids,
            'version': version
        }

def generate_aids_for_project_interactive():
    """Interactive AID generation for new projects"""
    print("=== Java Card AID Generator ===")

    # Get project information
    package_name = input("Enter package name (e.g., com.example.myapp): ").strip()
    if not package_name:
        package_name = "com.example.default"

    applet_names_input = input("Enter applet names (comma-separated, e.g., Applet1,Applet2): ").strip()
    if applet_names_input:
        applet_names = [name.strip() for name in applet_names_input.split(',') if name.strip()]
    else:
        applet_names = ['DefaultApplet']

    version = input("Enter version (default: 01): ").strip()
    if not version:
        version = '01'

    rid_type = input("Enter RID type (test/custom/demo/research, default: custom): ").strip().lower()
    if rid_type not in AIDGenerator.RIDS:
        print(f"Invalid RID type '{rid_type}'. Using default 'custom'.")
        rid_type = 'custom'

    # Generate AIDs
    generator = AIDGenerator(rid_type)
    project_info = {
        'package_name': package_name,
        'applet_names': applet_names,
        'version': version
    }

    results = generator.generate_project_aids(project_info)

    # Display results
    print("\n=== Generated AIDs ===")
    print(f"Package Name: {results['package_name']}")
    print(f"Package AID: {results['package_aid']}")
    print(f"Version: {results['version']}")
    print("\nApplet AIDs:")
    for applet in results['applets']:
        print(f"  {applet['name']}: {applet['aid']}")

    return results

# --- Project Template Creator (from Method 3) ---
def create_java_card_project_template(project_name: str, aids_info: Dict):
    """Create Java Card project template with proper AIDs"""

    # Use a directory within the current working directory for the new project
    template_dir = f"./{project_name}"
    os.makedirs(template_dir, exist_ok=True)
    os.makedirs(f"{template_dir}/src", exist_ok=True)

    package_name_path = aids_info.get('package_name', 'com.example.default').replace('.', '/')
    os.makedirs(f"{template_dir}/src/{package_name_path}", exist_ok=True)

    # Create build configuration (using a simple properties file)
    build_config = f"""# Java Card Build Configuration
# Generated for project: {project_name}

PACKAGE_AID = {aids_info.get('package_aid', 'A000000151000000')}
PACKAGE_NAME = {aids_info.get('package_name', 'com.example.default')}
VERSION = {aids_info.get('version', '01')}

# Applet Configuration
"""

    for applet in aids_info.get('applets', []):
        build_config += f"APPLET_{applet['name'].upper()}_AID = {applet['aid']}\n"

    with open(f"{template_dir}/build.properties", 'w') as f:
        f.write(build_config)

    # Create Java source template for each applet
    for applet in aids_info.get('applets', [{'name': 'DefaultApplet', 'aid': 'A000000151000000'}]):
        java_template = f"""package {aids_info.get('package_name', 'com.example.default')};

import javacard.framework.*;
import javacard.security.*;

public class {applet['name']} extends Applet {{

    // AID: {applet['aid']}

    // Define the Applet AID as a byte array
    private static final byte[] APPLET_AID = {{
        {', '.join([f'(byte)0x{applet["aid"][i:i+2]}' for i in range(0, len(applet["aid"]), 2)])}
    }};

    // Define the Package AID as a byte array (optional, but good practice)
    private static final byte[] PACKAGE_AID = {{
        {', '.join([f'(byte)0x{aids_info.get('package_aid', 'A000000151000000')[i:i+2]}' for i in range(0, len(aids_info.get('package_aid', 'A000000151000000')), 2)])}
    }};


    private {applet['name']}() {{
        // Register the applet with the JCRE
        register(APPLET_AID, (short) 0, (byte) APPLET_AID.length);
    }}

    public static void install(byte[] bArray, short bOffset, byte bLength) {{
        // Create an instance of the applet and register it
        new {applet['name']}().register(bArray, (short) (bOffset + bArray[bOffset]), (byte) bArray[(short) (bOffset + bArray[bOffset])]);
    }}

    public void process(APDU apdu) {{
        // Check if the applet is being selected
        if (selectingApplet()) {{
            return;
        }}

        byte[] buffer = apdu.getBuffer();
        short bytesRead = apdu.setIncomingAndReceive();

        // Implement your applet logic here based on incoming APDU commands
        // Example: Process a simple command
        // if (buffer[ISO7816.OFFSET_INS] == (byte) 0x00) {{
        //     // Handle command 0x00
        //     short le = apdu.setOutgoing();
        //     apdu.setOutgoingLength((short) 5);
        //     buffer[0] = (byte) 0x01; // Example response data
        //     buffer[1] = (byte) 0x02;
        //     buffer[2] = (byte) 0x03;
        //     buffer[3] = (byte) 0x90; // SW1
        //     buffer[4] = (byte) 0x00; // SW2
        //     apdu.sendBytes((short) 0, (short) 5);
        // }} else {{
        //     ISOException.throwIt(ISO7816.SW_INS_NOT_SUPPORTED);
        // }}
    }}
}}
"""
        applet_file_path = f"{template_dir}/src/{package_name_path}/{applet['name']}.java"
        with open(applet_file_path, 'w') as f:
            f.write(java_template)

    print(f"Project template created in: {template_dir}")
    print("Remember to add build scripts (e.g., Ant, Gradle) and a Makefile for compilation.")
    return template_dir

# --- Main Execution Block ---
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 aid_manager.py <command> [args]")
        print("Commands:")
        print("  analyze <path_to_cap_file>   - Analyze an existing CAP file to extract AIDs.")
        print("  generate                     - Interactively generate AIDs for a new project.")
        print("  create-project <project_name> - Create a basic project template with generated AIDs.")
        sys.exit(1)

    command = sys.argv[1]

    if command == "analyze":
        if len(sys.argv) != 3:
            print("Usage: python3 aid_manager.py analyze <path_to_cap_file>")
            sys.exit(1)
        cap_file_path = sys.argv[2]
        analyze_cap_file(cap_file_path)

    elif command == "generate":
        if len(sys.argv) != 2:
             print("Usage: python3 aid_manager.py generate")
             sys.exit(1)
        generate_aids_for_project_interactive()

    elif command == "create-project":
        if len(sys.argv) != 3:
            print("Usage: python3 aid_manager.py create-project <project_name>")
            sys.exit(1)
        project_name = sys.argv[2]
        print(f"Generating AIDs for project '{project_name}'...")
        # Generate AIDs non-interactively for template creation
        generator = AIDGenerator('custom') # Use default custom RID
        # Use project name for package name and a single applet named after the project
        project_info = {
            'package_name': f"com.example.{project_name.lower()}",
            'applet_names': [project_name],
            'version': '01'
        }
        aids_info = generator.generate_project_aids(project_info)
        print("\nUsing generated AIDs:")
        print(f"  Package AID: {aids_info['package_aid']}")
        for applet in aids_info['applets']:
             print(f"  Applet AID ({applet['name']}): {applet['aid']}")
        print()
        create_java_card_project_template(project_name, aids_info)

    else:
        print(f"Unknown command: {command}")
        print("Usage: python3 aid_manager.py <command> [args]")
        print("Commands:")
        print("  analyze <path_to_cap_file>   - Analyze an existing CAP file to extract AIDs.")
        print("  generate                     - Interactively generate AIDs for a new project.")
        print("  create-project <project_name> - Create a basic project template with generated AIDs.")
        sys.exit(1)
