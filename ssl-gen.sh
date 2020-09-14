#!/bin/bash

echo -e "\e[33m Generation started... \e[39m"

###############################################################################
## Suppress screen output
###############################################################################
{

###############################################################################
## Go to script directory
###############################################################################
SCRIPT_DIR=`dirname $0`
cd "${SCRIPT_DIR}"

###############################################################################
## Automation generate CA and client openSSL keys and certificates
###############################################################################
PATHTOSSLDIR="${SCRIPT_DIR}"         ## Path to store SSL keys and certificates
SSLHOSTNAME='109.87.52.51'           ## DNS1 Hostname or external IP address
SSLIPADR='109.87.52.51'              ## External IP address

ROOTCAKEYNAME='root-ca'              ## Name root CA key, certificate
ROOTCAKEYBIT='4096'                  ## Size root CA key in bits
ROOTCACRTDAYS='365'                  ## Validity in days

CLIENTKEYNAME='client'               ## Name client key, certificate and certificate requst
CLIENTKEYBIT='2048'                  ## Size client key in bits
CLIENYKEYDAYS='365'                  ## Validity in days

ROOTCAINFO_C='UA'                    ## Country
ROOTCAINFO_ST='Kharkov'              ## State
ROOTCAINFO_L='Kharkov'               ## Location
ROOTCAINFO_O='Podrepny'              ## Organization
ROOTCAINFO_OU='Web'                  ## Organizational Unit
ROOTCAINFO_CN='root_cert'            ## Common Name FQDN {fully qualified domain name}

CLIENTINFO_C="${ROOTCAINFO_C}"       ## Country
CLIENTINFO_ST="${ROOTCAINFO_ST}"     ## State
CLIENTINFO_L="${ROOTCAINFO_L}"       ## Location
CLIENTINFO_O="${ROOTCAINFO_O}"       ## Organization
CLIENTINFO_OU="${CLIENTKEYNAME}"     ## Organizational Unit
CLIENTINFO_CN="${SSLHOSTNAME}"       ## Common Name FQDN {fully qualified domain name}
###############################################################################

###############################################################################
## Generate root CA - RSA PRIVATE KEY
###############################################################################
openssl genrsa -out ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.key ${ROOTCAKEYBIT}

###############################################################################
## Generate root CA - CERTIFICATE
###############################################################################
openssl req -x509 -new -nodes -key ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.key \
  -sha256 \
  -days ${ROOTCACRTDAYS} \
  -out ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.crt \
  -subj "/C=${ROOTCAINFO_C}/ST=${ROOTCAINFO_ST}/L=${ROOTCAINFO_L}/O=${ROOTCAINFO_O}/OU=${ROOTCAINFO_OU}/CN=${ROOTCAINFO_CN}/"

###############################################################################
## Generate Client RSA PRIVATE KEY
###############################################################################
openssl genrsa -out ${PATHTOSSLDIR}/${CLIENTKEYNAME}.key ${CLIENTKEYBIT}

###############################################################################
## Generate Client CERTIFICATE REQUEST
###############################################################################
openssl req -new -out ${PATHTOSSLDIR}/${CLIENTKEYNAME}.csr \
  -key ${PATHTOSSLDIR}/${CLIENTKEYNAME}.key \
  -subj "/C=${CLIENTINFO_C}/ST=${CLIENTINFO_ST}/L=${CLIENTINFO_L}/O=${CLIENTINFO_O}/OU=${CLIENTINFO_OU}/CN=${CLIENTINFO_CN}/"

###############################################################################
## Signing a Client CSR with a root certificate = client CERTIFICATE
###############################################################################
openssl x509 -req \
  -in ${PATHTOSSLDIR}/${CLIENTKEYNAME}.csr \
  -CA ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.crt \
  -CAkey ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.key \
  -CAcreateserial -out ${PATHTOSSLDIR}/${CLIENTKEYNAME}.crt \
  -days ${CLIENYKEYDAYS} \
  -sha256 \
  -extfile <(cat <<EOF
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names
    [ alt_names ]
    DNS.1 = ${SSLHOSTNAME}
    IP.1 = ${SSLIPADR}
EOF)

###############################################################################
## Сombining two certificates root CA and client to ${CLIENTKEYNAME}.pem
###############################################################################
cat ${PATHTOSSLDIR}/${CLIENTKEYNAME}.crt ${PATHTOSSLDIR}/${ROOTCAKEYNAME}.crt > ${PATHTOSSLDIR}/${CLIENTKEYNAME}.pem
} &> /dev/null

###############################################################################
## Print report
###############################################################################
echo -e "\e[32m Generation finished \e[39m"
