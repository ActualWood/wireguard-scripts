#!/bin/bash
#WGNewPeer.sh -- KtW 12.16.2019s
echo "W00d.ROCKS Wireguard Server New Peer"
#things needed --- Set on server:  Peer PSK, Client Public Key
#rhings needed --- Set on Client Interface:  Client key public, PSK
#things needed --- set by Client config: Client Private key, PSK, Server Public Key,
[[ $UID == 0 ]] || { echo "You must be root user to run this. Sudo This Script."; exit 1; }
read -p 'PeerName (E.G. MOB01, TES01): ' PeerName
read -p 'Existing Wireguard Interface:  ' WGInterface
read -p 'Public Server Address (DNS name / IP):  ' ServEndPoint

happysad=`wg show $WGInterface`

if [[ $happysad = "Unable to access interface: No such device" ]]; then
echo "Error, Unable to access interface: No such device - $WGInterface"; exit 1;
fi
ServerPubKey=`wg show $WGInterface public-key`
ServPort=`wg show $WGInterface listen-port`
PeerPSK=`wg genpsk`
UsedWGIP=`wg show $WGInterface allowed-ips | cut -f 2 | sed '/(none)/d' | sed 's/192.168.0.0\/16//' | sed 's/\/32//' | sed 's/\/24//'`
echo "IP Addresses in use:"
echo  "$UsedWGIP"
read -p 'Choose IP in range not listed above:  ' ClientIPaddr
readonly ClientPrivateKey=$(wg genkey)
readonly ClientPublicKey=$(echo ${ClientPrivateKey} | wg pubkey)

readonly PeerFile="/etc/wireguard/peers/"$PeerName".conf"
readonly WGFile="/etc/wireguard/"$WGInterface".conf"

echo "Creating Peer File for $PeerName $ClientPublicKey at:  $PeerFile"
echo "Edit WG Int .Conf File at:  $WGFile"
echo "Server:  $ServEndPoint:$ServPort $ServerPubKey"
read -p 'Press any key to save to config, CTRL-C to cancel' > /dev/nul
echo $PeerPSK > /etc/wireguard/peers/$PeerName.psk
wg set $WGInterface peer $ClientPublicKey preshared-key /etc/wireguard/peers/$PeerName.psk allowed-ips $ClientIPaddr/32
rm /etc/wireguard/peers/$PeerName.psk
touch $PeerFile
cat << EOF >> $PeerFile
[Interface]
Address = $ClientIPaddr/24
PrivateKey = $ClientPrivateKey
DNS = 10.13.37.1,1.1.1.1

[Peer]
PublicKey = $ServerPubKey
PresharedKey = $PeerPSK
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $ServEndPoint:$ServPort
EOF
echo "Generate Client QR Code:"
qrencode -t ansiutf8 < $PeerFile
exit
