#!/usr/bin/env bash
set -euo pipefail

echo "=== Java Card build: SMSInterceptor ==="

# --- CORRECTED CONFIGURATION ---
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
JAVA_CARD_HOME="$HOME/Desktop/glo/java_card_devkit_tools-bin-v25.0-b_470-23-APR-2025"
APPLET_SRC_DIR="$HOME/Desktop/glo/my_applets"

# --- FIXED AID SYNTAX (PROPER DISTINCT VALUES) ---
PKG_NAME="sms.interceptor"
PKG_AID="A00000006203010C0101"           # 9 bytes (18 hex chars) - Package AID
APPLET_CLASS="SMSInterceptor"
APPLET_AID="A00000006203010C010101"      # 10 bytes (20 hex chars) - Applet AID
VERSION="1.0"

OUT_DIR="$APPLET_SRC_DIR/build"
CLASS_DIR="$OUT_DIR/classes"

rm -rf "$OUT_DIR"
mkdir -p "$CLASS_DIR"

echo "--> 1/3  Compiling Java sources ..."
javac \
  -g:none \
  -source 1.8 -target 1.8 \
  -classpath "$JAVA_CARD_HOME/lib/api_classic-3.2.0.jar" \
  -d "$CLASS_DIR" \
  "$APPLET_SRC_DIR/sms/interceptor/SMSInterceptor.java"

echo "--> 2/3  Converting to CAP ..."
# Use the shell script wrapper with proper environment
JAVA_HOME="$JAVA_HOME" "$JAVA_CARD_HOME/bin/converter.sh" \
  -out CAP \
  -exportpath "$JAVA_CARD_HOME/lib" \
  -classdir "$CLASS_DIR" \
  -applet "$APPLET_AID" "$PKG_NAME.$APPLET_CLASS" \
  -pkg "$PKG_AID" "$PKG_NAME" "$VERSION" \
  "$PKG_NAME"

CAP_PATH="$CLASS_DIR/javacard/$PKG_NAME/package.cap"

if [[ ! -f "$CAP_PATH" ]]; then
  echo "❌ CAP not generated!"; exit 1
fi

cp "$CAP_PATH" "$OUT_DIR/sms_interceptor.cap"

echo "--> 3/3  Generating HEX ..."
xxd -p "$OUT_DIR/sms_interceptor.cap" | tr -d '\n' > "$OUT_DIR/sms_interceptor.hex"

echo "✅  Finished:"
ls -lh "$OUT_DIR"/sms_interceptor.*
