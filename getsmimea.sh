#!/bin/sh

# Creates SMIMEA DNS record from S/MIME certifiate
# v.20170606 (c)2017 by Max Kostikov http://kostikov.co e-mail: max@kostikov.co
#
# Usage: getsmimea.sh usage selector type /path/to/cert
#

# Read parameters
if [ $# -ne 4 ]
then
        echo "Insufficient arguments!"
        echo "$0 usage selector type /path/to/cert"
        exit 1
fi
if [ ! -f $4 ]
then
        echo "Certificate file '$4' not found!"
        exit 1
fi

# Detect certificate type
openssl x509 -in $4 -noout 2>/dev/null
if [ $? != 0 ]
then
        echo "Unsupported certificate type!"
        exit 1
fi

case $1 in
        0) echo "PKIX-TA not supported"; exit 1;;
        1) echo "PKIX-EE not supported"; exit 1;;
        2) ;;
        3) ;;
        *) echo "Wrong usage argument value '$1'!"; exit 1;;
esac
case $2 in
        0) c1=":"; c2="openssl x509 -in $4 -outform DER";;
        1) c1="openssl x509 -in $4 -noout -pubkey"; c2="openssl pkey -pubin -outform DER";;
        *) echo "Wrong selecor argument value '$2'!"; exit 1;;
esac
case $3 in
        0) hash=`$c1 | $c2 | hexdump -ve '/1 "%02x"'`;;
        1) hash=`$c1 | $c2 | sha256`;;
        2) hash=`$c1 | $c2 | sha512`;;
        *) echo "Wrong type argument value '$3'!"; exit 1;;
esac

# Get e-mail address from certs CN=
email=`openssl x509 -noout -subject -nameopt multiline -in $4 | sed -n 's/ *commonName *= //p'`
local=`echo $email | cut -d '@' -f 1`
domain=`echo $email | cut -d '@' -f 2`
if [ "$local" = "$domain" ]
then
        echo "Wrong e-mail address <$email> in CN!"
        exit 1
fi

echo "`sha256 -s $local | cut -d ' ' -f 4 | cut -c 1-56`._smimecert.$domain     IN SMIMEA $1 $2 $3 ("
echo -n $hash | fold -w64 | sed 's/.*/  "&"/'
echo ") ; $email"
