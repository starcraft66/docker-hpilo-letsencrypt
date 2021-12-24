#!/usr/bin/env bash
# Fix for newlines disappearing
IFS=
set -e

if ! [ -z ${DEBUG+x} ]; then
	set -x
fi

if [ -z ${ILO_USERNAME+x} ]; then
	echo "ILO_USERNAME not set!"
	exit 1
fi
if [ -z ${ILO_PASSWORD+x} ]; then
	echo "ILO_PASSWORD not set!"
	exit 1
fi
if [ -z ${ILO_DOMAIN+x} ]; then
	echo "ILO_DOMAIN not set!"
	exit 1
fi
if [ -z ${LE_EMAIL+x} ]; then
	echo "LE_EMAIL not set!"
	exit 1
fi

# Check if the certificate is expiring soon
echo | openssl s_client -servername $ILO_DOMAIN -connect $ILO_DOMAIN:443 2>/dev/null | openssl x509 -noout -checkend 2592000
if [ "$?" == "1" ]; then
# Expiring in less than one month. We need to renew

# Tell the iLO to start generating a private key and certificate signing request
curl -sS -k -X POST -H "Content-Type: application/json" -d '{ "Action": "GenerateCSR", "Country": "x", "State": "x", "City": "x", "OrgName": "x", "OrgUnit": "x", "CommonName": "'$ILO_DOMAIN'"}' -u $ILO_USERNAME:$ILO_PASSWORD https://$ILO_DOMAIN/redfish/v1/Managers/1/SecurityService/HttpsCert/

# Attempt to grab the request
resp=$(curl -sS -k -u $ILO_USERNAME:$ILO_PASSWORD https://$ILO_DOMAIN/redfish/v1/Managers/1/SecurityService/HttpsCert/ | jq -r .CertificateSigningRequest)
echo "resp: $resp"
while [ "$resp" == "0" -o "$resp" == "" -o "$resp" == "null" ]; do
        # The private key has not yet been generated
        sleep 10
        # get the req
        resp=$(curl -sS -k -u $ILO_USERNAME:$ILO_PASSWORD https://$ILO_DOMAIN/redfish/v1/Managers/1/SecurityService/HttpsCert/ | jq -r .CertificateSigningRequest)
	echo "resp: $resp"
done

# Sign the request and obtain a certificate
if [[ -f ".lego/certificates/$ILO_DOMAIN.crt" ]]; then
	lego --server ${LE_SERVER-https://acme-v02.api.letsencrypt.org/directory} --email $LE_EMAIL --dns ${DNS_PROVIDER-cloudflare} --accept-tos --csr <(echo $resp) renew
else
	lego --server ${LE_SERVER-https://acme-v02.api.letsencrypt.org/directory} --email $LE_EMAIL --dns ${DNS_PROVIDER-cloudflare} --accept-tos --csr <(echo $resp) run
fi

# Parse the cert back into something HPiLO will understand
ilo_cert=$(cat .lego/certificates/$ILO_DOMAIN.crt | awk  '{gsub(" ","\\n")};1'|sed 's/\(.*\)\\n/\1 /'|sed '0,/\\n/s/\\n/ /')

# Install the certificate and reset iLO4
curl -sS -k -X POST -H "Content-Type: application/json" -d "{ \"Action\": \"ImportCertificate\", \"Certificate\": \"$(echo $ilo_cert)\" }" -u $ILO_USERNAME:$ILO_PASSWORD https://$ILO_DOMAIN/redfish/v1/Managers/1/SecurityService/HttpsCert/

fi
