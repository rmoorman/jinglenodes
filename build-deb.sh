#!/bin/bash
#
# Authors: Jorge Espada <jespada@yuilop.com> & Manuel Rubio <manuel@yuilop.com>
# 
# You need to have installed rubygems, fpm[0] gem (gem install fpm) and build-essential
# [0] https://github.com/jordansissel/fpm/wiki


# 
# Usage: ./build-deb.sh username directory_name
# example: ./build-deb.sh sjin360 sjinglenodes-in-360
#          (install path will be /opt/sjinglenodes-in-360)
#

USER=jnode
SERVER_USER=$1
GROUP=jnode
PROJECT=$2

INSTDIR=$(pwd)/installdir
FPM=$(gem which fpm | sed 's/\/lib\/fpm.rb/\/bin\/fpm/g')
TAG=$(git describe --always --tag)

if [ ! -z "$3" ]; then
    TAG="$3"
fi

#check if gem and fpm are installed
echo "You must have rubygems, fpm, and build-essential installed..."

gem list --local | grep fpm

if [[ $? -ne 0 ]]; then
    echo "Please verify the output of: gem list --local | grep fpm , remember you need tubygems and fpm installed"
    exit 1
fi

#clean compile and make the package
rm -rf deps/*
rm -rf apps/*/logs
rm -rf apps/*/.eunit
rm -rf apps/*/doc
rebar clean get-deps compile && rebar doc eunit skip_deps=true && rebar generate

if [[ $? -ne 0 ]]; then
    echo "Please check dependencies, compilation went wrong"
    exit 1
fi

rm -rf $INSTDIR
mkdir -p $INSTDIR/$PROJECT
cp -a rel/jinglenodes/* $INSTDIR/$PROJECT/

# generate postinst script

cat debian/postinst.head > $INSTDIR/postinst
echo "SERVER_USER=$SERVER_USER" >> $INSTDIR/postinst
echo "SERVER_GROUP=$GROUP" >> $INSTDIR/postinst
echo "SERVER_HOME=/opt/$PROJECT" >> $INSTDIR/postinst
cat debian/postinst.tail >> $INSTDIR/postinst

#build the package
pushd $INSTDIR
$FPM -s dir -t deb -n $PROJECT -v $TAG -C $INSTDIR --description "JingleNodes Erlang Server" -p $PROJECT-VERSION_ARCH.deb --after-install postinst --config-files /opt/$PROJECT/etc/app.config --prefix /opt --deb-user $USER --deb-group $GROUP --url http://www.upptalk.com/ --vendor Yuilop --maintainer '"Raul Martinez" <raul.martinez@upptalk.com>' $PROJECT

