#!/bin/sh

# Rotate ZSK key pair for DNSSEC zone
# v.20171023 (c)2016-2017 by Max Kostikov http://kostikov.co e-mail: max@kostikov.co
#
# 0 5 * * * root /path/to/dnszskrotate.sh >/dev/null 2>&1

# Warning!
# Require ldns toolset
# Uses dnsnewserial.sh and dnssignzone.sh scripts placed in same directory

## Settings
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
zonedir="$nsddir/zones"                 # path to zones dir
arcdir="$nsddir/archive"                # path to archive storage
log="$nsddir/var/log/dnsrotate.log"     # path to log file

## Write to log function
logwrite ()
{
        echo "`date '+%Y-%m-%d %H:%M:%S'` $1" >> $log
}

logwrite "Starting ZSK pairs rotation"

## Initial checks
# create main archive directory if doesn't exist
if [ ! -d $arcdir ]
then
        mkdir $arcdir
        logwrite "  Creating main archive directory $arcdir"
fi

# Start zones directories scan
for i in `find $zonedir/*.* -type d`
do
        dom=`basename $i`               # current domain name

        # is zone DNSSEC ?
        if [ `ls $i/*.key | wc -l` -gt 0 ]
        then
                logwrite "  $dom zone in work"
        ## 1. Make cleanup
                # create archive subdirectory if don't exist
                if [ ! -d $arcdir/$dom ]
                then
                        mkdir $arcdir/$dom
                        logwrite "    Creating archive directory for $dom zone"
                fi

                # get into current zone location
                cd $i

                # find oldest expired ZSK...
                exp=`find *.key -mtime +${arcage}s -exec grep -il '256 3' {} \; | xargs ls -t | head -1`
                if [ -n "$exp" ]
                then
                        keyfs=`basename $exp .key`
                        logwrite "    Moving ZSK pair $keyfs to archive"
                        # ...and move it to archive
                        mv $keyfs.* $arcdir/$dom/
                fi

        ## 2. Generate new ZSK
                # find actual keys
                cur=`find *.key -mtime -${oldage}s -exec grep -il '256 3' {} \;`
                # it must exist at least two actual keys
                if [ `echo $cur | wc -w` -lt 2 ]
                then
                        # check interval beetween keys
                        chk=`find *.key -mtime -${keygap}s -exec grep -il '256 3' {} \;`
                        # if there is no fresh keys do main procedure
                        if [ -z "$chk" ]
                        then
                                # create new keys pair
                                alg=`find *.key -exec egrep -il '257 3' {} \; | xargs ls -t | head -1 | cut -d + -f 2 | sed 's/^0*//'`
                                                # detect algorithm
                                new=`ldns-keygen -a $alg $dom`
                                logwrite "    New ZSK pair $new was created"

        ## 3. Add new ZSK to zone
                                # delete previous prepublished DNSKEY
                                sed -i.bak "/DNSKEY/d" $dom.zone

                                # prepublish new key
                                cat $new.key >> $dom.zone
                                logwrite "    Public key $new added to zone"

        ## 4. Add old ZSK to zone
                                old=`find *.key \! -newer $new.key -exec grep -il '256 3' {} \; | xargs ls -t | sed -n 3p`
                                if [ -n "$old" ]
                                then
                                        cat $old >> $dom.zone
                                        logwrite "    Old public key `basename $old .key` added to zone"
                                fi
                                # generating new zone serial
                                logwrite "    Serial in $dom zone changed to `$mypath/dnsnewserial.sh $i/$dom.zone`"

        ## 5. Sign zone
                                logwrite "    Zone was signed using `$mypath/dnssignzone.sh $i/$dom.zone` keys"
                        fi
                fi
                logwrite "  $dom zone processed"
        else
                logwrite "  $dom zone skipped"
        fi
done

## Infrom DNS server about changes
if [ -n "$new" ]
then
        logwrite "  DNS server zones reloaded `nsd-control reload`"
fi

logwrite "ZSK pairs rotation finished"
