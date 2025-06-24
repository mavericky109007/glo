package sms.interceptor;

import javacard.framework.APDU;
import javacard.framework.Applet;
import javacard.framework.ISO7816;
import javacard.framework.ISOException;
import javacard.framework.Util;

public class SMSInterceptor extends Applet {

    // AID of the applet (matching the build script)
    private static final byte[] APPLET_AID = {
        (byte) 0xA0, (byte) 0x00, (byte) 0x00, (byte) 0x01, (byte) 0x51,
        (byte) 0xDE, (byte) 0x0F, (byte) 0xFA, (byte) 0x32, (byte) 0xAC,
        (byte) 0x01, (byte) 0x01 // New Applet AID bytes
    };

    // Instruction byte for the command to intercept SMS (keeping from previous version)
    // private static final byte INS_INTERCEPT_SMS = (byte) 0x01; // Not used in current process method, but keep for potential future use or context

    // **** INSTALL METHOD ****
    // Standard install method that registers the applet with the AID provided during installation
    public static void install(byte[] bArray, short bOffset, byte bLength) {
        // bArray contains the install parameters
        // bArray[bOffset] is the length of the AID
        // The AID bytes start at bOffset + 1
        new SMSInterceptor().register(bArray, (short) (bOffset + 1), bArray[bOffset]);
    }

    // **** CONSTRUCTOR ****
    private SMSInterceptor() {
        // Register the applet with its hardcoded AID
        // This is often done in the constructor when the AID is known at build time
        register(APPLET_AID, (short) 0, (byte) APPLET_AID.length);
    }

    // **** MAIN DISPATCH ****
    @Override
    public void process(APDU apdu) {
        byte[] buf = apdu.getBuffer();

        /* Example “select” handling */
        if (selectingApplet()) {
            return;
        }

        /* Very simple demo INS = 0x50 */
        if (buf[ISO7816.OFFSET_INS] == (byte) 0x50) {
            ISOException.throwIt(ISO7816.SW_NO_ERROR);
        } else {
            ISOException.throwIt(ISO7816.SW_INS_NOT_SUPPORTED);
        }
    }
}
