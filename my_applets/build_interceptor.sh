#!/bin/bash

# Use a directory where the current user has permissions
APPLET_DIR="./my_applets"
JAVA_CARD_HOME="/opt/java_card_kit" # Assuming JCDK is still here if needed later

# Ensure the applet directory exists (write_to_file should create it, but good practice)
mkdir -p $APPLET_DIR

# Define AIDs and package info (read from build.properties or hardcode if preferred)
# For now, hardcoding based on the generated build.properties
PACKAGE_AID="A000000151DE0FFA32AC01"
PACKAGE_NAME="sms.interceptor" # Matches the package declaration in SMSInterceptor.java
APPLET_AID="A000000151DE0FFA32AC01A148"
APPLET_NAME="SMSInterceptor" # Matches the applet class name
PACKAGE_VERSION="0.0" # Use a simple version

# Ensure the applet source is in the correct package structure within APPLET_DIR
# The SMSInterceptor.java file should be in $APPLET_DIR/sms/interceptor/
# Assuming SMSInterceptor.java is already moved to my_applets/sms/interceptor/

echo "Compiling Java Card applet: $APPLET_NAME"

# Compile Java source to class files
# Use -d to specify output directory, -classpath to include JCDK API
$JAVA_CARD_HOME/bin/javac -g -d $APPLET_DIR -classpath $JAVA_CARD_HOME/api/api.jar $APPLET_DIR/sms/interceptor/$APPLET_NAME.java

if [ $? -ne 0 ]; then
    echo "❌ Java compilation failed."
    exit 1
fi

echo "Converting class files to CAP file..."

# Convert class files to CAP file using converter tool
# -out specifies output components (ALL includes CAP)
# -exportpath specifies location of exported packages (JCDK API)
# -applet specifies Applet AID, Class Name
# -pkg specifies Package AID, Package Name, Package Version
$JAVA_CARD_HOME/bin/converter -out ALL \
    -exportpath $JAVA_CARD_HOME/api/api.exp \
    -applet ${APPLET_AID} ${PACKAGE_NAME}.${APPLET_NAME} \
    -pkg ${PACKAGE_AID} ${PACKAGE_NAME} ${PACKAGE_VERSION} \
    $APPLET_DIR/${PACKAGE_NAME//.//}/

if [ $? -ne 0 ]; then
    echo "❌ CAP conversion failed."
    exit 1
fi

# The converter creates a directory structure like $APPLET_DIR/sms/interceptor/javacard/sms/interceptor/
# The CAP file is usually named package.cap within that structure
# Find the generated CAP file
GENERATED_CAP_DIR="$APPLET_DIR/${PACKAGE_NAME//.//}/javacard/${PACKAGE_NAME//.//}"
GENERATED_CAP_FILE="$GENERATED_CAP_DIR/package.cap"

if [ ! -f "$GENERATED_CAP_FILE" ]; then
    echo "❌ Generated CAP file not found at $GENERATED_CAP_FILE"
    exit 1
fi

# Copy the generated CAP file to the main applet directory
cp "$GENERATED_CAP_FILE" $APPLET_DIR/sms_interceptor.cap

echo "Creating hex representation for OTA installation..."

# Create hex representation for OTA installation
xxd -p $APPLET_DIR/sms_interceptor.cap | tr -d '\n' > $APPLET_DIR/sms_interceptor.hex

echo "✅ Applet compiled to CAP file and hex"
