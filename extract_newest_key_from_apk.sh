#!/bin/bash
set -x
#set -e
if [ ! -d ojoc-keyhack ]; then
	echo "ojoc-keyhack does not appear to exist in this directory. Trying to add it as a submodule..."
	git submodule add https://bitbucket.org/cfib90/ojoc-keyhack.git ojoc-keyhack
fi
name='com.tellm.android.app'
path=$(adb shell pm path $name | sed 's/package://g' | tr -d '\r')

tmp_folder=$(mktemp -d )
adb pull $path ${tmp_folder}/${name}.apk &> /dev/null
unzip -qq -n -d ${tmp_folder} ${tmp_folder}/${name}.apk &> /dev/null
key=
#set +e
for i in $(ls ${tmp_folder}/lib/x86/lib*.so); do
	key=$(ojoc-keyhack/x86/decrypt-liba-readelf.sh $i)
	if [ ! $(echo ${key} | grep "Function 'HmacInterceptor_init' not found") ]; then
		key=$(echo ${key} | awk '{print $NF}')
		break
	else
		key="ERROR"
	fi
done

if [ "${key}" = "ERROR" ]; then
	echo "Failed to extract the key. Stoping"
	exit
fi
version=$(adb shell dumpsys package com.tellm.android.app | grep versionName | tr '=' ' ' | awk '{print $2}')

echo "${key}:${version}" >> keyfile.txt
sed -i "s/secret = '.*'.encode('ascii')/secret = '${key}'.encode('ascii')/g" src/jodel_api/jodel_api.py
sed -i "s/version = '.*'/version = '${version}'/g" src/jodel_api/jodel_api.py

echo "${key}:${version}"
rm -r $tmp_folder
