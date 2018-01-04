#!/bin/sh

# Sign DNS zone using DNSSEC keys
# v.20170531 (c)2016-2017 by Max Kostikov http://kostikov.co e-mail: max@kostikov.co
#
# Usage: dnssignzone.sh /path/to/zone/file

# Warning!
# Requires ldns toolset

# Check arguments
if [ $# -ne 1 ]
then
        echo "Provide /path/to/zone/file as argument!"
        exit 1
fi

# is zone file exist?
if [ ! -f $1 ]
then
        echo "Zone file $1 not found!"
        exit 1
fi

## Setttings
# read settings
mypath=`dirname $0 | xargs readlink -f`
if [ ! -f ${mypath}/dnstools.cf ]
then
        echo "Configuration file dnstools.cf not found!"
        exit 1
else
        . ${mypath}/dnstools.cf
fi

# prepare parameters
zonedir=`dirname $1`                    # path to zone dir

# Zone is DNSSEC
if [ `ls $zonedir/*.key | wc -l` -eq 0 ]
then
        echo "Zone have not any keys!"
        exit 1
fi

sigopt="-n -t 100 -s `head -c 512 /dev/random | shasum | cut -b 1-16`"
                                        # zone signing options

## Get actual keys list
ZSK=`find $zonedir/*.key -mtime -${arcage}s -exec grep -il '256 3' {} \; | xargs ls -tr | head -1 | sed 's/\.key$//'`
                                        # get oldest existing ZSK
KSK=`find $zonedir/*.key -exec egrep -il '(257|385) 3' {} \; | sed 's/\.key$//'`
                                        # get all existing KSK

if [ -z "$ZSK" -o -z "$KSK" ]
then
        echo "Full keys set not found in $zonedir !"
        exit 1
fi

## Signing zone
ldns-signzone $sigopt $1 $ZSK $KSK
[ $? != 0 ] && exit 1

## Print keys names as confirmation
echo "$ZSK $KSK" | sed 's|'$zonedir'/||g'
