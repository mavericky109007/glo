#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 <IMSI> <MSISDN>"
    exit 1
fi
IMSI=$1
MSISDN=$2
echo "Setting up subscriber: IMSI=$IMSI, MSISDN=$MSISDN"
mongosh mongodb://ota-mongodb:27017/open5gs --eval "
db.subscribers.insertOne({
    'imsi': '$IMSI',
    'msisdn': '$MSISDN',
    'security': {
        'k': '465B5CE8B199B49FAA5F0A2EE238A6BC',
        'opc': 'E8ED289DEBA952E4283B54E88E6183CA',
        'amf': '8000',
        'sqn': NumberLong(0)
    },
    'ambr': {
        'uplink': NumberLong(1000000000),
        'downlink': NumberLong(1000000000)
    },
    'pdn': [{
        'apn': 'internet',
        'type': 0,
        'qos': {
            'qci': 9,
            'arp': {
                'priority_level': 8,
                'pre_emption_capability': 1,
                'pre_emption_vulnerability': 1
            }
        }
    }]
})
"
echo "Subscriber setup completed!"
