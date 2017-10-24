#!/bin/sh

# Change DNS zone serial in YYYYMMDDNN format
# v.20161112 (c)2016 by Max Kostikov http://kostikov.co e-mail: max@kostikov.co
#
# Usage: dnsnewserial.sh /path/to/zone/file
#
# Warning!
# Serial must be placed in separate string with text "serial" as comment.

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

# get current serial
curser=`grep "serial" $1 | tr -cd "[:digit:]"`

if [ -z "$curser" ]
then
        echo "Serial not found in $1 file!"
        exit 1
fi

newser=`date '+%Y%m%d'`

if [ `expr $curser : $newser` = 8 ]     # if serial today was already changed
then
        newser=`expr $curser + 1`       # increment it
else
        newser=${newser}00              # else assign new
fi

# write new serial to zone file
sed -i.bak "s/.*serial/         $newser \; serial/" $1

# print new serial as confirmation
echo $newser
