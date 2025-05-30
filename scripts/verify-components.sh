#!/bin/bash

echo "=== Component-Specific Verification ==="

IMAGE_NAME="ota-testing:latest"

echo "1. Verifying UHD installation..."
docker run --rm "$IMAGE_NAME" /opt/uhd/install/bin/uhd_config_info --version || echo "❌ UHD verification failed"

echo ""
echo "2. Verifying critical dependencies..."
docker run --rm "$IMAGE_NAME" pkg-config --modversion liburing || echo "❌ liburing verification failed"
docker run --rm "$IMAGE_NAME" pkg-config --modversion libmnl || echo "❌ libmnl verification failed"

echo ""
echo "3. Verifying Osmocom components..."
docker run --rm "$IMAGE_NAME" which osmo-msc || echo "❌ OsmoMSC not found"
docker run --rm "$IMAGE_NAME" which osmo-hlr || echo "❌ OsmoHLR not found"

echo ""
echo "4. Verifying Open5GS components..."
docker run --rm "$IMAGE_NAME" which open5gs-mmed || echo "❌ Open5GS MME not found"

echo ""
echo "5. Verifying Python dependencies..."
docker run --rm "$IMAGE_NAME" python3 -c "
import sys
modules = ['uhd', 'mako', 'ruamel.yaml', 'smpplib', 'smartcard']
failed = []
for module in modules:
    try:
        __import__(module)
        print(f'✅ {module}')
    except ImportError:
        print(f'❌ {module}')
        failed.append(module)

if failed:
    print(f'Failed modules: {failed}')
    sys.exit(1)
else:
    print('✅ All Python modules imported successfully')
"

echo ""
echo "6. Verifying OTA applets..."
docker run --rm "$IMAGE_NAME" ls -la /opt/ota/applets/ || echo "❌ OTA applets directory not found"

echo ""
echo "7. Verifying TUN interface script..."
docker run --rm "$IMAGE_NAME" test -x /usr/local/bin/setup-tun.sh && echo "✅ TUN setup script available" || echo "❌ TUN setup script missing"

echo ""
echo "=== Component Verification Complete ===" 