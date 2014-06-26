#!/bin/bash 
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2009, 2010, 2013, 2014 Zimbra, Inc.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 


LOCAL=0
LABEL=zimbra.liquidsys.com@zimbra:zcs


if [ "$1" = "--local" ]; then
    LOCAL=1
    shift
elif [ "$1" = "--label" ]; then
  LABEL=$2
  shift; shift;
fi

if [ $LABEL = "zimbra.liquidsys.com@zimbra:zcs" ]; then
  LABEL="/zimbra.rpath.org@rpl:1//zimbra.liquidsys.com@zimbra:devel//zcs" 
fi
BUILDROOT=$1
RELEASETAG=$4

cd $BUILDROOT
cvc checkout group-dist=$LABEL 2> /dev/null
if [ $? != 0 ]; then
  echo "cvc checkout group-dist=$LABEL failed"
  exit 1
fi
cd group-dist
cvc cook group-dist=$LABEL --debug
if [ $? -ne 0 ]; then
  echo "cvc cook group-dist failed"
  exit 1
fi

cd $BUILDROOT

TROVE=`conary rq --full-versions --flavors group-dist=$LABEL`
if [ $? != 0 ]; then
  exit 1
fi
echo "Building ISO Image $BUILDROOT/zcs-${RELEASETAG}.iso..."
BUILD=`rbuilder build-create zimbra "$TROVE" installable_iso --wait --option "baseFileName zcs-${RELEASETAG}" | awk -F= '{print $NF}'`
if [ $? -eq 0 ]; then
  echo "Getting URL for Build $BUILD"
  ISO=`rbuilder build-url $BUILD | head -1`
  echo "Retrieving image from $ISO"
  if [ x"$ISO" != "x" ]; then
    wget -qO $BUILDROOT/zcs-${RELEASETAG}.iso $ISO
    ln -s $BUILDROOT/zcs-${RELEASETAG}.iso $BUILDROOT/zcs.iso
  fi
fi

echo "Building VMWare Image $BUILDROOT/zcs-${RELEASETAG}-vmware.zip..."
BUILD=`rbuilder build-create zimbra "$TROVE" vmware_image --wait --option 'vmMemory 512' --option 'freespace 500' --option "baseFileName zcs-${RELEASETAG}-vmware"  | awk -F= '{print $NF}'`
if [ $? -eq 0 ]; then
  echo "Getting URL for Build $BUILD"
  ZIP=`rbuilder build-url $BUILD | head -1`
  if [ x"$ZIP" != "x" ]; then
    echo "Retrieving image from $ZIP"
    wget -qO $BUILDROOT/zcs-${RELEASETAG}-vmware.zip $ZIP
    ln -s $BUILDROOT/zcs-${RELEASETAG}-vmware.zip $BUILDROOT/zcs-vmware.zip
  fi
fi

if [ "x$ISO" = "x" -o "x$ZIP" = "x" ]; then
  exit 1
else 
  exit 0
fi
  
