#!/bin/bash
# Portable & simple HW-Info script - quickly & easily get an idea of the HW you're working on
# - works on any OS that can run bash
# - tested on Linux, MacOS & Cygwin
#
# * By Kordian Witek <code@kordian.com>
#

# store LSCPU info, as we will use it quite often
LSCPU=/tmp/lscpu-$$
lscpu 2>/dev/null > $LSCPU

#
# VM TYPE (if VM)
#
VM=`awk '/[Hh]ypervisor [Vv]endor:/{print $NF}' $LSCPU`

if [ -z "$VM" ]; then
  if lspci 2>/dev/null |grep -q vmware; then
    VM="VMware"
  fi
fi
[ -z "$VM" ] && dmesg 2>/dev/null |grep -qi 'vmware' && VM="VMware"
[ -z "$VM" ] && dmesg 2>/dev/null |grep -q 'KVM' && VM="KVM"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -qi 'vmware' /var/log/dmesg && VM="VMware"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -q 'KVM' /var/log/dmesg && VM="KVM"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -qi 'xen' /var/log/dmesg && VM="Xen"
[ -z "$VM" -a -e /proc/cpuinfo ] && grep -q "^[Ff]lags.*hypervisor" /proc/cpuinfo && VM="VM"


#
# HARDWARE TYPE
#
HW=`cat /sys/firmware/devicetree/base/mode /proc/device-tree/model /sys/devices/virtual/dmi/id/chassis_vendor /sys/class/dmi/id/board_vendor /sys/devices/virtual/dmi/id/sys_vendor /sys/devices/virtual/dmi/id/product_name /sys/class/dmi/id/product_family /sys/class/dmi/id/product_version 2>/dev/null |sed 's/[^[:print:]]//' |sort -u |grep -v '^\.*$' |xargs |sed 's/No Enclosure//; s/VMware, Inc.//; s/VMware Virtual Platform//; s/Intel Corporation//; s/Raspberry Pi/RaspberryPi/; s/ Plus/+/; s/ Model//; s/None//; s/ + /+/g; s/  / /g; s/^ //; s/ $//'`
[ -z "$HW" ] && HW=`dmesg 2>/dev/null |grep "DMI:" |sed 's/.*: //' |awk -F/ '{print $1}' |sed 's/VMware, Inc. VMware Virtual Platform//; s/ Plus/+/; s/ Model//'`

# Mac
if [ -z "$HW" -a "`uname -s`" = "Darwin" ]; then
  HW=`defaults read ~/Library/Preferences/com.apple.SystemProfiler.plist 'CPU Names' |cut -sd '"' -f 4 |uniq |sed 's/, \(One|Two|Three|Four|Five\) .* Ports)/)/'`
  [ -z "$HW" ] && HW=`curl -s https://support-sp.apple.com/sp/product?cc=$( system_profiler SPHardwareDataType |awk '/Serial/ {print $4}' |cut -c 9- ) |sed 's|.*<configCode>\(.*\)</configCode>.*|\1|'`
  [ -z "$HW" ] && HW=`sysctl hw.model 2>/dev/null |sed 's/.*: //; s/MacBook\([A-Z]\)/MacBook \1/; s/\([a-z]\)\([0-9]\)/\1 \2/;'`
fi

# Windows
if [ -z "$HW" ]; then
  HW=`wmic csproduct get vendor, name, version 2>/dev/null |awk -F '  ' '/^[^N][^a][^m][^e]/{print $2,$3,$1}'`
  EXTRA_HW=`wmic computersystem get manufacturer, model 2>|/dev/null |awk -F '  ' '/^[^M][^a][^n][^u]/{print $1,$2}'`
  if ! echo "$HW" | grep -q "$EXTRA_HW"; then
    HW="$HW $EXTRA_HW"
  fi
fi

[ -n "$HW" ] && HW="`echo $HW | sed 's/^ //; s/LENOVO/Lenovo/; s/ Inc\.//; s/^[0-9][0-9][^ ]* //'`"   # do not allow HW starting with digits
[ -n "$HW" ] && HW=": $HW"

#
# CPU MODEL, CORES & TYPE
#
CPU_MODEL=`awk -F '  ' '/Model name:/{print $NF}' $LSCPU |sed 's/Intel(R) Xeon(R) CPU //; s/Intel(R) Core(TM) //; s/ [Rr]ev / Rev/g; s/ Processor//; s/ CPU//; s/Virtual/Virt/; s/version /v/; s/^ //'`
[ -z "$CPU_MODEL" ] && CPU_MODEL=`cat /proc/cpuinfo 2>/dev/null |awk -F: '/^model name/{print $NF}' |uniq |sed 's/Intel(R) Xeon(R) CPU //; s/Intel(R) Core(TM) //; s/ [Rr]ev / Rev/g; s/ Processor//; s/ CPU//; s/Virtual/Virt/; s/version /v/; s/^ //'`
[ -z "$CPU_MODEL" ] && CPU_MODEL=`sysctl machdep.cpu.brand_string 2>/dev/null | awk -F: '{print $NF}' |sed 's/Intel(R) Xeon(R) CPU //; s/Intel(R) Core(TM) //; s/ [Rr]ev / Rev/g; s/ Processor//; s/ CPU//; s/Virtual/Virt/; s/version /v/; s/^ //'`

if echo "$CPU_MODEL" |grep -Eq 'MHz|GHz'; then
  CPU_FREQ=""
else
  CPU_FREQ=`awk '/CPU max MHz/{printf("%.1fGHz", $NF/1000)}' $LSCPU`
  [ -z "$CPU_FREQ" ] && CPU_FREQ=`awk '/CPU MHz/{printf("%.1fGHz", $NF/1000)}' $LSCPU`
  [ -n "$CPU_FREQ" ] && CPU_FREQ=" $CPU_FREQ"
fi

NO_OF_CPU=`awk '/^CPU\(s\):/{print $NF}' $LSCPU`
[ -z "$NO_OF_CPU" ] && NO_OF_CPU=`grep -c "^processor" /proc/cpuinfo 2>/dev/null`
[ -z "$NO_OF_CPU" ] && NO_OF_CPU=`sysctl hw.ncpu 2>/dev/null | awk '{print $NF}'`

# CPU TYPE (vCPU or not)
CPU_TYPE="CPU"
[ -n "$VM" ] && CPU_TYPE="vCPU"


#
# MEMORY
#
MEM=`free -k 2>/dev/null |awk '/^Mem:/{printf("%.0fGB", $2/1024/1024)}'`
[ -z "$MEM" ] && MEM=`sysctl hw.memsize 2>/dev/null | awk '{printf("%.0fGB", $2/1024/1024/1024)}'`


#
# OS
#
OS_TYPE=`uname -o 2>/dev/null |awk -F/ '{print $NF}'`
[ -z "$OS_TYPE" ] && OS_TYPE=`uname -s 2>/dev/null | sed 's/^Darwin$/MacOS (Darwin)/'`
[ -s /etc/redhat-release ] && OS_TYPE="RHEL"

OS_VERSION=`cat /etc/redhat-release 2>/dev/null |awk '{print $(NF-1)}'`
[ -z "$OS_VERSION" ] && OS_VERSION=`cat /etc/*release* 2>/dev/null |awk -F= '/^(NAME|VERSION)=/{print $NF}' |sed 's/"//g; s#GNU/Linux##; s/ (\(.*\))/ \u\1/' |xargs`
[ -z "$OS_VERSION" -a -x "/usr/sbin/system_profiler" ] && OS_VERSION=`system_profiler SPSoftwareDataType 2>/dev/null | awk -F: '/System Version:/{print $NF}' | sed 's/^ //; s/ (.*$//'`
[ -z "$OS_VERSION" ] && OS_VERSION=`uname -r |sed 's/(.*//'`

OS_YEAR=`uname -v |grep -Eo "[12][09][0-9]{2}" |sed "s/^[12][09]\([0-9][0-9]\)$/\'\1/"`



#
# 64bit of 32bit
#
BIT_TYPE=`uname -m | sed 's/.*64$/64bit/; s/.*32$/32bit/; s/i[36]86/32bit/; s/armv7./32bit/'`



#
# DISK SIZE & FS TYPE
#
HD_SIZE=`lsblk -o "NAME,MAJ:MIN,RM,SIZE,RO,FSTYPE,MOUNTPOINT,UUID" 2>/dev/null |awk '/^(sd|mmcblk)/{print $4}' |head -5 |xargs |sed 's/ /+/g'`
[ -z "$HD_SIZE" -a -x "/usr/sbin/diskutil" ] && HD_SIZE=`diskutil list 2>/dev/null | awk '/:.*disk0$/{print $3$4}' |sed 's/^\*//; s/\.0GB/GB/'`
[ -z "$HD_SIZE" ] && HD_SIZE=`df -hl 2>/dev/null |awk '/[0-9]/{print $2}' |xargs |sed 's/ /+/g; s/Gi/GB/'`

FS_TYPE=`df -Th |awk '/\/$/{print $2}'`
[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list | awk '/Apple_HFS.*disk0/{print $2}' | sed 's/Apple_HFS/hfs/'`
[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list | awk '/disk0/{print $2}' |grep APFS | sed 's/Apple_APFS/apfs/'`



#
# WHEN BUILT - can use / or /etc (for Mac, we use the pkgutil query of BaseSystem)
#
BUILT=`ls -lact --full-time /etc 2>/dev/null |awk 'END {print $6}'`
[ "$BUILT" = "0" ] && BUILT=`ls -lact --full-time /etc |awk 'END {print $7}'`
[ -z "$BUILT" ] && BUILT=`date -r $( pkgutil --pkg-info com.apple.pkg.BaseSystem 2>/dev/null | awk '/install-time/{print $2}' ) 2>/dev/null`
[ -z "$BUILT" ] && BUILT=`date -r $( pkgutil --pkg-info com.apple.pkg.BaseSystemBinaries 2>/dev/null | awk '/install-time/{print $2}' ) 2>/dev/null`
[ -z "$BUILT" ] && BUILT=`date -r $( pkgutil --pkg-info com.apple.pkg.Core 2>/dev/null | awk '/install-time/{print $2}' ) 2>/dev/null`
[ -z "$BUILT" ] && BUILT=`date -r $( pkgutil --pkg-info com.apple.pkg.CoreFP 2>/dev/null | awk '/install-time/{print $2}' ) 2>/dev/null`
[ -z "$BUILT" ] && BUILT=`date -r $( pkgutil --pkg-info com.apple.pkg.macOSBrain 2>/dev/null | awk '/install-time/{print $2}' ) 2>/dev/null`
[ -n "$BUILT" ] && BUILT_FMT=`date "+%b'%g" -d "$BUILT" 2>/dev/null`
[ -n "$BUILT" -a -z "$BUILT_FMT" ] && BUILT_FMT=`echo $BUILT | grep -Eo "[12][09][0-9]{2}" |sed "s/^[12][09]\([0-9][0-9]\)$/\'\1/"`


#
# HOST & DOMAIN NAME
#
HOST=`uname -n |sed 's/\..*//'`
DOMAIN=`domainname 2>/dev/null |grep -v "none" | sed 's/\..*//'`
[ -z "$DOMAIN" ] && DOMAIN=`uname -n | sed 's/\.[a-z0-9-]*\.com//; s/^[a-z0-9-]*\.\([a-z0-9-]*\)/\1/; s/\..*//'`
if [ "$DOMAIN" = "$HOST" ]; then
  DOMAIN=""
else
  DOMAIN="/`echo $DOMAIN |tr a-z A-Z`"
fi

[ -x /sbin/ifconfig ] && IP=`/sbin/ifconfig |awk '/inet.*broadcast/ && !/127.0/{print $2}' |tail -1`
[ -z "$IP" ] && IP=`hostname -i | awk '{print $1}'`
[ -z "$IP" -o "$IP" = "127.0.0.1" -o "$IP" = "127.0.1.1" ] && IP=`hostname -I | awk '{print $1}'`
if [ -n "$IP" ]; then
  DNS_NAME=`nslookup "$IP" |awk '/Name:|name =/{print $NF}' |awk -F. '{print $1}'`
  if [ -n "$DNS_NAME" -a "$DNS_NAME" != "$HOST" ]; then
    HOST_EXTRA=" ($DNS_NAME)"
  fi
fi


#
# /FINAL PRINT/
#
[ -z "$VM" ] && VM="BareMetal"
echo "$HOST$DOMAIN$HOST_EXTRA: $OS_TYPE $OS_VERSION/$OS_YEAR, $VM$HW, $MEM RAM, $NO_OF_CPU x $CPU_TYPE $CPU_MODEL$CPU_FREQ, $BIT_TYPE, $HD_SIZE Disk/$FS_TYPE, Built $BUILT_FMT" |sed -e 's/\b\([A-Za-z0-9]\+\)[ ,\n]\1/\1/g'

# clean-up
rm -f $LSCPU

# EOF
