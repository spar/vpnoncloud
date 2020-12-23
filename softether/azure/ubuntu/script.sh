#!/bin/sh
apt-get update -y \
    && apt-get install build-essential -y \
    && wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v4.29-9680-rtm.tar.gz -O softether.tar.gz \
    && mkdir softether \
    && tar xzvf softether.tar.gz -C softether --strip-components=1 \
    && cd softether \
    && ./configure \
    && make \
    && make install


PSK=$1
USERNAME=$2
USERPASSWORD=$3
SERVERPASSWORD=$4

echo "starting vpn server"
/usr/bin/vpnserver start
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCipherSet DHE-RSA-AES256-SHA

echo "Enabling l2tp and set psk on default hub"
/usr/bin/vpncmd localhost /SERVER /CSV /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:$PSK /DEFAULTHUB:DEFAULT

echo "Enabling securenat"
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SecureNatEnable
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD NatSet /MTU:1500 /LOG:no /TCPTIMEOUT:3600 /UDPTIMEOUT:1800

echo "Setting OpenVPN port to 443"
/usr/bin/vpncmd localhost /SERVER /CSV /CMD OpenVpnEnable yes /PORTS:443

echo "Disabling logs"
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable packet
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable security

echo "Creating a user"
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD UserCreate $USERNAME /GROUP:none /REALNAME:none /NOTE:none
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD UserPasswordSet $USERNAME /PASSWORD:$USERPASSWORD

echo "Setting default hub password"
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SetHubPassword $SERVERPASSWORD

echo "Setting Server password"
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerPasswordSet $SERVERPASSWORD