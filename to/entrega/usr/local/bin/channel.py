#!/usr/bin/env python

import sys, os

temp = {"0":[1,2,3,4,5,6,7,8,9,10,11,12,13]}
channels = {value:key for key in temp for value in temp[key]}

for line in sys.stdin:
    fields = line.replace(':',' ').split()
    if fields[0] == 'Channel':
        if fields[1] == '1':
            channels[1] = int(channels[1]) + 1
        if fields[1] == '2':
            channels[2] = int(channels[2]) + 1
        if fields[1] == '3':
            channels[3] = int(channels[3]) + 1
        if fields[1] == '4':
            channels[4] = int(channels[4]) + 1
        if fields[1] == '5':
            channels[5] = int(channels[5]) + 1
        if fields[1] == '6':
            channels[6] = int(channels[6]) + 1
        if fields[1] == '7':
            channels[7] = int(channels[7]) + 1
        if fields[1] == '8':
            channels[8] = int(channels[8]) + 1
        if fields[1] == '9':
            channels[9] = int(channels[9]) + 1
        if fields[1] == '10':
            channels[10] = int(channels[10]) + 1
        if fields[1] == '11':
            channels[11] = int(channels[11]) + 1
        if fields[1] == '12':
            channels[12] = int(channels[12]) + 1
        if fields[1] == '13':
            channels[13] = int(channels[13]) + 1

best = min(channels, key=channels.get)
if channels[best+1] == '0':
    if channels[best+2] == '0':
        if channels[best+3] == '0':
            best = best+2

conf = ["interface=wlan0\n",
    "ssid=SEAXmola\n",
    "hw_mode=g\n",
    "channel="+str(best)+"\n",
    "ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]\n",
    "wmm_enabled=0\n",
    "macaddr_acl=0\n",
    "auth_algs=1\n",
    "wpa=2\n",
    "ignore_broadcast_ssid=0\n",
    "wpa_passphrase=SEAX2018\n",
    "wpa_key_mgmt=WPA-PSK\n",
    "wpa_pairwise=TKIP\n",
    "rsn_pairwise=CCMP\n"]

#fo = open("/etc/hostapd/hostapd.conf", "w+")
#fo.writelines(conf)
cmd="hostapd_cli SET channel "+str(best)
os.system("hostapd_cli DISABLE")
os.system(cmd)
os.system("hostapd_cli ENABLE")
