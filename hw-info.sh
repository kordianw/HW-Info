#!/bin/bash
# Portable & simple HW-Info script - quickly & easily get an idea of the HW you're working on
# - works on any OS that can run bash
# - tested on Linux, MacOS, AWS/GCP/Azure, Cygwin & WSL
#
# RUN DIRECTLY FROM GITHUB:
# $ curl -sSL https://github.com/kordianw/HW-Info/raw/master/hw-info.sh | bash
#
# * By Kordian W. <code [at] kordy.com>, January 2019
#

# DOCUMENTATION:
#
# Provides the following information as a 1-liner:
# - hostname (and domain, if appropriate)
# - OS type & OS name (eg: Ubuntu) and version
# - Distribution name (or MacOS release friendly name)
# - year of OS release
# - Bare Metal or VM, VM type
# - HW type & model (incl hypervisor type)
# - How much RAM (in GB)
# - How many CPUs (or cores/threads)
# - Real or virtual CPUs? (CPUs vs vCPUs)
# - CPU model/type and CPU speed (in GHz)
# - CPU Architecture (eg: Haswell, Skylake, Ice Lake, etc)
# - 32bit or 64bit system?
# - Local Disk sizes (in human friendly format)
# - FS type (eg: ext4, ntfs, btrfs)
# - When was the OS built? (based on dates of some key root files)
#
# How to run (takes no params):
#
# $ ./hw-info.sh
#

##################################################

# store LSCPU info, as we will use it quite often
LSCPU=/tmp/lscpu-$$
lscpu 2>/dev/null > $LSCPU

#
# VM TYPE (if VM)
#
VM=`awk -F: '/[Hh]ypervisor [Vv]endor:/{print $NF}' $LSCPU | sed 's/^ *//; s/Windows Subsystem for Linux/WSL/'`

if [ -z "$VM" ]; then
  if lspci 2>/dev/null |grep -q vmware; then
    VM="VMware"
  fi
fi
[ -z "$VM" ] && dmesg 2>/dev/null |grep -qi 'vmware' && VM="VMware"
[ -z "$VM" ] && dmesg 2>/dev/null |grep -q 'KVM' && VM="KVM"
[ -z "$VM" ] && dmesg 2>/dev/null |grep -q 'gVisor' && VM="gVisor"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -qi 'vmware' /var/log/dmesg && VM="VMware"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -q 'KVM' /var/log/dmesg && VM="KVM"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -qi 'xen' /var/log/dmesg && VM="Xen"
[ -z "$VM" -a -s /var/log/dmesg ] && grep -q 'gVisor' /var/log/dmesg && VM="gVisor"
[ -z "$VM" -a -e /proc/cpuinfo ] && grep -q "^[Ff]lags.*hypervisor" /proc/cpuinfo && VM="VM"

if [ -n "$VM" ]; then
  VM_TYPE=`awk -F: '/[Vv]irtualization [Tt]ype/{print $NF}' $LSCPU | sed 's/^ *//'| egrep -v '^full$'`
  [ -n "$VM_TYPE" ] && VM="$VM/$VM_TYPE"
fi

# add the word VM to a non obvious hypervisor types
if [ -n "$VM" -a `echo $VM | egrep -ic 'VM|container'` -eq 0 ]; then
  VM=`echo "$VM VM" | sed 's/Microsoft VM/Hyper-V\/VM/'`
fi


#
# HARDWARE TYPE
#
HW=`cat /sys/firmware/devicetree/base/mode /proc/device-tree/model /sys/devices/virtual/dmi/id/chassis_vendor /sys/class/dmi/id/board_vendor /sys/devices/virtual/dmi/id/sys_vendor /sys/devices/virtual/dmi/id/product_name /sys/class/dmi/id/product_family /sys/class/dmi/id/product_version 2>/dev/null |sed 's/[^[:print:]]//' |sort -u |grep -v '^\.*$' |xargs |sed 's/No Enclosure//; s/VMware, Inc.//; s/VMware Virtual Platform//; s/innotek GmbH Oracle Corporation VirtualBox/Oracle VirtualBox/; s/Intel Corporation//; s/ Corporation//; s/UEFI Release v[0-9].[0-9]*//; s/Virtual Machine/VM/; s/Raspberry Pi/RaspberryPi/; s/ Plus/+/; s/ Model//; s/None//; s/HVM domU Xen/HVM domU/; s/ V[0-9]\.[0-9][0-9]*.*//; s/ + /+/g; s/\b\([A-Za-z]\+\)[ ,\n]\1/\1/g; s/\([^ ]*\) \([^ ]*\) \([^ ]*\) \(\2\) /\1 \2 \3 /g; s/  / /g; s/^[0-9]\.[0-9]* //; s/^ //; s/ $//' | awk '{for (i=1;i<=NF;i++) if (!a[$i]++) printf("%s%s",$i,FS)}{printf("\n")}'`
[ -z "$HW" ] && HW=`dmesg 2>/dev/null |grep "DMI:" |sed 's/.*: //' |awk -F/ '{print $1}' |sed 's/VMware, Inc. VMware Virtual Platform//; s/ Plus/+/; s/ Model//'`
# NOTE: to prune dups, can also use: awk -v RS="[ \n]+" '!n[$0]++' 

# Mac
if [ -z "$HW" -a "`uname -s`" = "Darwin" ]; then
  HW=`defaults read ~/Library/Preferences/com.apple.SystemProfiler.plist 'CPU Names' 2>/dev/null |cut -sd '"' -f 4 |uniq |sed 's/, \(One|Two|Three|Four|Five\) .* Ports)/)/'`
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

[ -n "$HW" ] && HW="`echo $HW | sed 's/^ //; s/LENOVO/Lenovo/; s/TOSHIBA/Toshiba/; s/Hewlett Packard/HP/; s/DELL/Dell/; s/ASUSTeK COMPUTER INC\./Asus/; s/ASUSTeK/Asus/; s/Hyper-V Microsoft VM/Microsoft Hyper-V/; s/ Corp\.//; s/ Inc\.//; s/_Droplet Droplet/ Droplet/; s/^[0-9][0-9][^ ]* //; s/ [0-9]\.[0-9][^ ]* / /;'`"   # do not allow HW starting with digits
[ -n "$HW" ] && HW=": $HW"
if [ -z "$HW" -a "$VM" = "VMware" ]; then
  VM="VM"
  HW=": VMware"
fi

# Kernel type, append to HW in the end
KERNEL_TYPE=""
KTYPE=`uname -r 2>/dev/null | egrep '^.*-[a-z][a-z]*$' |egrep -v '\-(generic|default)$' | sed 's/^.*-\([a-z][a-z]*$\)/\1/'`
if [ -n "$KTYPE" ]; then
  KERNEL_TYPE="/`echo $KTYPE | tr 'a-z' 'A-Z'`"
fi


#
# CPU MODEL, CORES & TYPE
#
CPU_MODEL=`awk -F '  ' '/Model name:/ && !/BIOS Model/{print $NF}' $LSCPU`
[ -z "$CPU_MODEL" ] && CPU_MODEL=`cat /proc/cpuinfo 2>/dev/null |awk -F: '/^model name/{print $NF}' | uniq`
[ -z "$CPU_MODEL" ] && CPU_MODEL=`sysctl machdep.cpu.brand_string 2>/dev/null | awk -F: '{print $NF}'`
if [ -n "$CPU_MODEL" -a "$CPU_MODEL" = "unknown" ]; then
  CPU_MODEL=`cat /proc/cpuinfo 2>/dev/null |awk -F: '/^vendor_id/{print $NF}' | uniq | sed 's/GenuineIntel/Intel/'`
fi
if [ -n "$CPU_MODEL" ]; then
  CPU_MODEL=`echo "$CPU_MODEL" | sed 's/Intel(R) Xeon(R) CPU //; s/Intel(R) Xeon(R) Platinum/Xeon Platinum/; s/Intel(R) Xeon(R) Gold/Xeon Gold/; s/Intel(R) Core(TM) //; s/Intel(R) Celeron(TM)/Celeron/; s/Intel(R) Pentium(R)/Pentium/; s/ [Rr]ev / Rev/g; s/ Processor//; s/ CPU//; s/Virtual/Virt/; s/version /v/; s/ [0-9][0-9]-Core$//; s/^ //; s/ $//; s/  / /g;'`

  # special translations for Google Cloud (GCP) cases
  CPU_MODEL=`echo "$CPU_MODEL" | sed 's/AMD EPYC 7B12/AMD EPYC 7B12\/7742/'`
fi

if echo "$CPU_MODEL" |grep -Eq 'MHz|GHz'; then
  CPU_FREQ=""
  CPU_MODEL="`echo $CPU_MODEL | sed 's/\(\.[0-9]\)0GHz/\1GHz/'`"
else
  CPU_FREQ=`awk '/CPU max MHz/{printf("%.2fGHz", $NF/1000)}' $LSCPU`
  [ -z "$CPU_FREQ" ] && CPU_FREQ=`awk '/CPU MHz/{printf("%.2fGHz", $NF/1000)}' $LSCPU`
  [ -n "$CPU_FREQ" ] && CPU_FREQ=" `echo $CPU_FREQ | sed 's/\(\.[0-9]\)0GHz/\1GHz/'`"
fi

NO_OF_CPU=`awk '/^CPU\(s\):/{print $NF}' $LSCPU`
[ -z "$NO_OF_CPU" ] && NO_OF_CPU=`grep -c "^processor" /proc/cpuinfo 2>/dev/null`
[ -z "$NO_OF_CPU" ] && NO_OF_CPU=`sysctl hw.ncpu 2>/dev/null | awk '{print $NF}'`

# CPU TYPE (vCPU or not)
CPU_TYPE="CPU"
[ -n "$VM" ] && CPU_TYPE="vCPU"

# add CPU architecture information
if [ -n "$CPU_MODEL" ]; then
  # INTEL: populate from: https://en.wikichip.org/wiki/intel/cpuid
  # years: https://en.wikipedia.org/wiki/List_of_Intel_CPU_microarchitectures

  # Note that Skylake+Cascade Lake share family/model, so need to look at actual model to work it out:
  # cascade lake 2nd gen stuff from https://www.intel.com/content/www/us/en/products/docs/processors/xeon/2nd-gen-xeon-scalable-spec-update.html
  # 2nd gen xeon scalable cpus: cascade lake sku is 82xx, 62xx, 52xx, 42xx 32xx W-32xx  from https://www.intel.com/content/www/us/en/products/docs/processors/xeon/2nd-gen-xeon-scalable-spec-update.html
  # skylake 1st gen stuff from https://www.intel.com/content/www/us/en/processors/xeon/scalable/xeon-scalable-spec-update.html
  # 1st gen xeon scalable cpus: 81xx, 61xx, 51xx, 81xxT, 61xxT 81xxF, 61xxF, 51xx, 41xx, 31xx, 51xxT 41xxT, 51xx7,
  CPU_NAME=`cat /proc/cpuinfo 2>/dev/null | awk '
  function decode_fam_mod(vndor, fam, mod, mod_nm) {
    if (vndor == "GenuineIntel") {
      # cpuid tables from https://en.wikichip.org/wiki/intel/cpuid
      dcd[1,1]="Ice Lake;19";              dcd[1,2] ="Family 6 Model 108";
      dcd[2,1]="Ice Lake;19";              dcd[2,2] ="Family 6 Model 106";
      dcd[3,1]="Skylake;15";               dcd[3,2] ="Family 6 Model 85"; # 06_55h  Intel always does the hex fam_model
      dcd[4,1]="Broadwell;14";             dcd[4,2] ="Family 6 Model 79"; # 06_4fh
      dcd[5,1]="Broadwell;14";             dcd[5,2] ="Family 6 Model 86"; # 06_56h
      dcd[6,1]="Haswell;13";               dcd[6,2] ="Family 6 Model 63"; # 06_3fh
      dcd[7,1]="Ivy Bridge;12";            dcd[7,2] ="Family 6 Model 62";
      dcd[8,1]="Sandy Bridge;11";          dcd[8,2] ="Family 6 Model 45"; # 06_2dh
      dcd[9,1]="Westmere;10";              dcd[9,2] ="Family 6 Model 44";
      dcd[10,1]="EX";                      dcd[10,2]="Family 6 Model 47";
      dcd[11,1]="Nehalem;08";              dcd[11,2]="Family 6 Model 46";
      dcd[12,1]="Lynnfield;08";            dcd[12,2]="Family 6 Model 30";
      dcd[13,1]="Bloomfield;08";           dcd[13,2]="Family 6 Model 26";
      dcd[14,1]="Penryn;07";               dcd[14,2]="Family 6 Model 29";
      dcd[15,1]="Harpertown, QC, Wolfdale, Yorkfield";  dcd[15,2]="Family 6 Model 23";

      dcd[16,1]="Ivy Bridge;12";           dcd[16,2]="Family 6 Model 58";

      dcd[17,1]="Skylake;15";              dcd[17,2]="Family 6 Model 94";
      dcd[18,1]="Skylake;15";              dcd[18,2]="Family 6 Model 78";

      dcd[19,1]="Kaby Lake;16";            dcd[19,2]="Family 6 Model 158";
      dcd[20,1]="Kaby Lake;16";            dcd[20,2]="Family 6 Model 142";

      dcd[21,1]="Ice Lake;19";             dcd[21,2]="Family 6 Model 126";
      dcd[22,1]="Ice Lake;19";             dcd[22,2]="Family 6 Model 125";

      str = "Family " fam " Model " mod;
      #printf("str= %s\n", str);
      res="";
      for(k=1;k <=21;k++) { if (dcd[k,2] == str) {res=dcd[k,1];break;}}
      if (k == 3) {
        # so Cooper Lake/Cascade Lake/SkyLake)
        if (match(mod_nm, / [86543]2[0-9][0-9]/) > 0) { res="Cascade Lake;19";} else
        if (match(mod_nm, / [86543]1[0-9][0-9]/) > 0) { res="Skylake;15";}
      }
      return res;
    }
  }
  /^vendor_id/ {
    vndr=$(NF);
  }
  /^cpu family/ {
    fam=$(NF);
  }
  /^model/ {
    if ($2 == ":") {
      mod=$(NF);
    }
  }
  /^model name/ {
#model name : Intel(R) Xeon(R) CPU E5-2620 v4 @ 2.10GHz
    n=split($0, arr, ":");
    mod_nm = arr[2];
    #printf("vndr= %s, fam= %s, mod= %s, mod_nm= %s\n", vndr, fam, mod, mod_nm);
    cpu_name=decode_fam_mod(vndr, fam, mod, mod_nm);
    printf("%s\n", cpu_name);
    exit;
  }
'`
  if [ -n "$CPU_NAME" ]; then
    # INTEL
    CPU_MODEL=`echo "$CPU_MODEL ($CPU_NAME)" | sed "s/;/'/"`
  else
    #
    # AMD: some of it is documented here:
    #      https://cloud.google.com/compute/docs/cpu-platforms
    #      https://en.wikipedia.org/wiki/Epyc
    #

    # AMD
    if echo "$CPU_MODEL" | egrep -q 'AMD EPYC (7351P|7401P|7551P|7251|7261|7281|7301|7351|7371|7401|7451|7501|7551|7571|7601)'; then
      CPU_NAME="Naples'17"
    elif echo "$CPU_MODEL" | egrep -q 'AMD EPYC (7B12|7232P|7302P|7402P|7502P|7702P|7252|7262|7272|7282|7302P|7352|7402P|7452|7502P|7532|7542|7552|7642|7662|7702P|7742|7F32|7F52|7F72)'; then
      CPU_NAME="Rome'19"
    elif echo "$CPU_MODEL" | egrep -q 'AMD EPYC (7B13|7773X|7763|7713|7713P|7663|7643|7573X|75F3|7543|7543P|7513|7453|7473X|74F3|7443|7443P|7413|7373X|73F3|7343|7313|7313P|72F3)'; then
      CPU_NAME="Milan'21"
    fi

    # AMD Results
    if [ -n "$CPU_NAME" ]; then
      CPU_MODEL="$CPU_MODEL ($CPU_NAME)"
    fi
  fi
fi


#
# MEMORY
#
MEM=`dmesg 2>/dev/null | awk '/Memory:.*K available/{print $4}' | sed 's/.*\///; s/K$//' | awk '{printf("%.0fGB\n", $1/1024/1024)}'`
[ -z "$MEM" ] && MEM=`free -k 2>/dev/null |awk '/^Mem:/{printf("%.0fGB", $2/1024/1024)}'`
[ -z "$MEM" -a -e /proc/meminfo ] && MEM=`awk '/^MemTotal:/{printf("%.0fGB", $2/1024/1024)}' /proc/meminfo 2>/dev/null`
if [ "$MEM" = "0GB" -o "$MEM" = "1GB" ]; then
  MEM=`dmesg | awk '/Memory:.*K available/{print $4}' | sed 's/.*\///; s/K$//' | awk '{printf("%.0fMB\n", $1/1024)}' | sed 's/^9..MB/1GB/; s/^1...MB/1GB/'`
  [ -z "$MEM" ] && MEM=`free -k 2>/dev/null |awk '/^Mem:/{printf("%.0fMB", $2/1024)}' | sed 's/^9..MB/1GB/; s/^1...MB/1GB/'`
  [ -z "$MEM" ] && MEM=`awk '/^MemTotal:/{printf("%.0fMB", $2/1024)}' /proc/meminfo`
fi

# MacOS
[ -z "$MEM" ] && MEM=`sysctl hw.memsize 2>/dev/null | awk '{printf("%.0fGB", $2/1024/1024/1024)}'`


#
# OS
#
OS_TYPE=`uname -o 2>/dev/null |awk -F/ '{print $NF}'`
[ -z "$OS_TYPE" ] && OS_TYPE=`uname -s 2>/dev/null | sed 's/^Darwin$/MacOS (Darwin)/'`
[ -s /etc/redhat-release ] && OS_TYPE="Linux RHEL"
[ -s /etc/fedora-release ] && OS_TYPE="Fedora Linux"
[ -s /etc/centos-release ] && OS_TYPE="Linux CentOS"
[ -s /etc/rocky-release ] && OS_TYPE="Rocky Linux"
[ -s /etc/debian-release ] && OS_TYPE="Debian Linux"

if [ -s /etc/redhat-release -a ! -s /etc/fedora-release -a ! -s /etc/centos-release -a ! -s /etc/rocky-release ]; then
  OS_VERSION=`cat /etc/redhat-release 2>/dev/null |awk '{print $(NF-1)}'`
elif [ -s /etc/fedora-release ]; then
  OS_VERSION=`cat /etc/fedora-release 2>/dev/null |awk '{print $3}'`
elif [ -s /etc/centos-release ]; then
  OS_VERSION=`cat /etc/centos-release 2>/dev/null |awk '{print $2,$3,$4,$5}' | xargs | sed 's/ release / /'`
elif [ -s /etc/rocky-release ]; then
  OS_VERSION=`cat /etc/rocky-release 2>/dev/null |awk '{print $4,$5,$6,$7}' | xargs | sed 's/ release / /'`
fi
[ -z "$OS_VERSION" ] && OS_VERSION=`cat /etc/*release* 2>/dev/null |sort |uniq |awk -F= '/^(NAME|VERSION)=/{print $NF}' |sed 's/"//g; s#GNU/Linux##; s/ (\(.*\))/ \u\1/' |xargs`
[ -z "$OS_VERSION" ] && OS_VERSION=`cat /etc/issue 2>/dev/null |sed 's/^Welcome to //i' | awk '{print $1,$2}' | xargs | sed 's/^ //; s/ $//'`
[ -z "$OS_VERSION" -a -x "/usr/bin/sw_vers" ] && OS_VERSION=`sw_vers -productVersion 2>/dev/null | sed 's/^ //; s/ (.*$//'`
[ -z "$OS_VERSION" -a -x "/usr/sbin/system_profiler" ] && OS_VERSION=`system_profiler SPSoftwareDataType 2>/dev/null | awk -F: '/System Version:/{print $NF}' | sed 's/^ //; s/ (.*$//'`
[ -z "$OS_VERSION" ] && OS_VERSION=`uname -r |sed 's/(.*//'`

# Debian & Ubuntu has a special format
if echo "$OS_VERSION" |grep -q Debian; then
  OS_VERSION=`echo $OS_VERSION | sed 's/\([0-9]\) \([A-Za-z]*\)/\1 "\l\2"/'`
elif echo "$OS_VERSION" |grep -q Ubuntu; then
  OS_VERSION=`echo $OS_VERSION | sed 's/LTS \([A-Z][a-z]* [A-Z][a-z]*\)$/LTS (\1)/; s/\([0-9]\) \([A-Z][a-z]* [A-Z][a-z]*\)$/\1 (\2)/;'`
fi

# MacOS releases: see here:
# https://en.wikipedia.org/wiki/MacOS_version_history#Releases
if [ "$OS_TYPE" = "MacOS (Darwin)" -o "$OS_TYPE" = "MacOS" -o "$OS_TYPE" = "Darwin" ]; then
  if [[ $OSTYPE == darwin22* ]]; then
    EXTRA_OS_INFO=' (Ventura)'
  elif [[ $OSTYPE == darwin21* ]]; then
    EXTRA_OS_INFO=' (Monterey)'
  elif [[ $OSTYPE == darwin20* ]]; then
    EXTRA_OS_INFO=' (Big Sur)'
  elif [[ $OSTYPE == darwin19* ]]; then
    EXTRA_OS_INFO=' (Catalina)'
  elif [[ $OSTYPE == darwin18* ]]; then
    EXTRA_OS_INFO=' (Mojave)'
  elif [[ $OSTYPE == darwin17* ]]; then
    EXTRA_OS_INFO=' (High Sierra)'
  elif [[ $OSTYPE == darwin16* ]]; then
    EXTRA_OS_INFO=' (Sierra)'
  elif [[ $OSTYPE == darwin15* ]]; then
    EXTRA_OS_INFO=' (El Capitan)'
  elif [[ $OSTYPE == darwin14* ]]; then
    EXTRA_OS_INFO=' (Yosemite)'
  elif [[ $OSTYPE == darwin13* ]]; then
    EXTRA_OS_INFO=' (Mavericks)'
  elif [[ $OSTYPE == darwin12* ]]; then
    EXTRA_OS_INFO=' (Mountain Lion)'
  elif [[ $OSTYPE == darwin11* ]]; then
    EXTRA_OS_INFO=' (Lion)'
  elif [[ $OSTYPE == darwin10* ]]; then
    EXTRA_OS_INFO=' (Snow Leopard)'
  fi
fi

OS_YEAR=`uname -v |grep -Eo "[12][09][0-9]{2}" |tail -1 |sed "s/^[12][09]\([0-9][0-9]\)$/\'\1/"`


#
# 64bit of 32bit
#
BIT_TYPE=`uname -m | sed 's/.*64$/64bit/; s/.*32$/32bit/; s/i[36]86/32bit/; s/armv7./32bit/'`


#
# DISK SIZE & FS TYPE
# - we also work out if it's an SSD or a HDD
# - we exclude anything in MB range, shoul be GB or higher
#
HD_SIZE=`lsblk -d -e 1,7 -o "NAME,MAJ:MIN,RM,SIZE,RO,FSTYPE,MOUNTPOINT,TYPE" 2>/dev/null |awk '/^(sd|vd|xvd|nvme|mmcblk|hd).* disk$/{print $4}' |egrep -v "K$|M$" |sed 's/\([0-9]\)\([A-Z]\)/\1 \2/' |awk '{ printf("%.0f%s\n", $1,$2) }' |head -3 |xargs |sed 's/ /+/g'`
[ -z "$HD_SIZE" -a -x "/usr/sbin/diskutil" ] && HD_SIZE=`diskutil list 2>/dev/null | awk '/:.*disk0$/{print $3$4}' |sed 's/^\*//;'`
[ -z "$HD_SIZE" ] && HD_SIZE=`df -hl 2>/dev/null |egrep -v '^none|^cgroup|tmpfs|devtmpfs|nfs|smbfs|cifs|squashfs|fuse.sshfs' |awk '/[0-9]/{print $2}'| grep -v "M$" |xargs |sed 's/ /+/g; s/Gi/GB/'`
[ -z "$HD_SIZE" ] && HD_SIZE=`df -hl 2>/dev/null |egrep -v '^none|^cgroup|tmpfs|devtmpfs|nfs|smbfs|cifs|squashfs|fuse.sshfs' |awk '/[0-9]/{print $2}'| xargs |sed 's/ /+/g; s/Gi/GB/'`
[ -z "$HD_SIZE" ] && HD_SIZE=`df -hl / 2>/dev/null |egrep -v '^cgroup|tmpfs|devtmpfs|nfs|smbfs|cifs|squashfs|fuse.sshfs' |awk '/[0-9]/{print $2}'| xargs |sed 's/ /+/g; s/Gi/GB/'`

# format nicely
[ -n "$HD_SIZE" ] && HD_SIZE=`echo $HD_SIZE |sed 's/GB$/G/; s/\.[0123]G/G/'`

# SSD or HDD?
if [ "`lsblk -d -e 1,7 -o NAME,TYPE 2>/dev/null |grep disk | wc -l`" = 1 ]; then
  if lsblk -d -e 1,7 -o NAME,ROTA,TYPE 2>/dev/null | grep disk| egrep -q "mmcblk.* 0 "; then
    HD_TYPE_SDD="SDHC"
  elif lsblk -d -e 1,7 -o NAME,ROTA,TYPE 2>/dev/null | grep disk| egrep -q "nvme.* 0 "; then
    HD_TYPE_SDD="NVMe SSD"
  fi
fi
[ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`lsblk -d -e 1,7 -o NAME,ROTA,TYPE 2>/dev/null | awk '/^(sd|vd|xvd|nvme|mmcblk|hd).* disk$/{print $2}' | sed 's/^1$/HDD/; s/^0$/SSD/' |sort |uniq |xargs |sed 's/ /+/g;'`
[ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`diskutil info disk0 2>/dev/null | awk '/Solid State/{print $NF}' | sed 's/Yes/SSD/; s/No/HDD/'`
if which wmic >&/dev/null; then
  [ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`wmic diskdrive list 2>/dev/null |grep PHYSICALDRIVE0 |grep -ci NVME | sed 's/^1$/NVMe SSD/; s/^0$/HDD/'`
  [ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`wmic diskdrive get Caption, MediaType, Index, InterfaceType 2>/dev/null |egrep -v 'USB|External' | grep " 0 " |grep -ci NVME | sed 's/^1$/NVMe SSD/; s/^0$/HDD/'`
  [ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`wmic diskdrive list 2>/dev/null |grep PHYSICALDRIVE0 |grep -ci SSD | sed 's/^1$/SSD/; s/^0$/HDD/'`
  [ -z "$HD_TYPE_SDD" ] && HD_TYPE_SDD=`wmic diskdrive get Caption, MediaType, Index, InterfaceType 2>/dev/null |egrep -v 'USB|External' | grep " 0 " |grep -ci SSD | sed 's/^1$/SSD/; s/^0$/HDD/'`
fi

HD_TYPE="Disk"
[ -n "$HD_TYPE_SDD" ] && HD_TYPE=$HD_TYPE_SDD

# FS Type?
FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup -x overlay 2>/dev/null | egrep -v '/boot|/usr/lib/modules' |awk '/\/$/{print $2}' | sort -u |xargs |sed 's/ /+/g'`
[ -z "$FS_TYPE" ] && FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup -x overlay 2>/dev/null | egrep -v '/boot|/usr/lib/modules' |awk '/ \//{print $2}' | sort -u |xargs |sed 's/ /+/g'`
[ -z "$FS_TYPE" ] && FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup -x overlay / /root /usr 2>/dev/null |awk '/ \//{print $2}' | sort -u |xargs |sed 's/ /+/g'`
[ -z "$FS_TYPE" ] && FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup -x overlay /home 2>/dev/null |awk '/ \//{print $2}' | sort -u |xargs |sed 's/ /+/g'`
[ -z "$FS_TYPE" ] && FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup -x overlay 2>/dev/null |awk '/ \//{print $2}' | sort -u |xargs |sed 's/ /+/g'`
[ -z "$FS_TYPE" ] && FS_TYPE=`df -Th -x tmpfs -x devtmpfs -x nfs -x smbfs -x cifs -x squashfs -x fuse.sshfs -x cgroup 2>/dev/null |awk '/ \//{print $2}' | sort -u |xargs |sed 's/ /+/g'`

# Apple
[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list 2>/dev/null | awk '/Apple_HFS.*disk0/{print $2}' | sed 's/Apple_HFS/hfs/'`
[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list 2>/dev/null | awk '/disk0/{print $2}' |grep APFS | sed 's/Apple_APFS/apfs/' | egrep -v 'apfs_Recovery|apfs_IŚĆ'`

[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list 2>/dev/null | awk '/Apple_HFS.*disk1/{print $2}' | sed 's/Apple_HFS/hfs/'`
[ -z "$FS_TYPE" -a -x "/usr/sbin/diskutil" ] && FS_TYPE=`diskutil list 2>/dev/null | awk '/disk1/{print $2}' |grep APFS | sed 's/Apple_APFS/apfs/' | egrep -v 'apfs_Recovery|apfs_IŚĆ'`


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
[ -z "$DOMAIN" -o "$DOMAIN" = "$HOST" ] && DOMAIN=`uname -n | sed 's/\.[a-z0-9-]*\.com//; s/^[a-z0-9-]*\.\([a-z0-9-]*\)/\1/; s/\..*//'`
[ -n "$DOMAIN" -a "$DOMAIN" = "localdomain" ] && DOMAIN=
if [ -z "$DOMAIN" -o "$DOMAIN" = "$HOST" ]; then
  [ -z "$IP" ] && IP=`hostname -i 2>/dev/null | sed 's/^::1 //;' | awk '{print $1}' | grep -v 127.0.0.1`
  [ -z "$IP" -a -x /sbin/ifconfig ] && IP=`/sbin/ifconfig 2>/dev/null |awk '/inet.*(broadcast|Bcast)/ && !/127.0/{print $2}' |tail -1 | sed 's/^.*://'`
  [ -z "$IP" -o "$IP" = "127.0.0.1" -o "$IP" = "127.0.1.1" ] && IP=`hostname -I 2>/dev/null | awk '{print $1}'`
  if [ -n "$IP" ]; then
    DOMAIN=`nslookup "$IP" 2>/dev/null |awk '/Name:|name =/{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $2}' | sed 's/[^A-Za-z0-9_-]*//g'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "ip" ] && DOMAIN=`nslookup "$IP" 2>/dev/null |awk '/Name:|name =/{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}' | sed 's/[^A-Za-z0-9_-]*//g'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "bc" ] && DOMAIN=`nslookup "$IP" 2>/dev/null |awk '/Name:|name =/{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}' | sed 's/[^A-Za-z0-9_-]*//g'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "compute-1" ] && DOMAIN=`nslookup "$IP" 2>/dev/null |awk '/Name:|name =/{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}' | sed 's/[^A-Za-z0-9_-]*//g'`

    [ -z "$DOMAIN" ] && DOMAIN=`host "$IP" 2>/dev/null |awk '{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $2}'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "ip" ] && DOMAIN=`host "$IP" 2>/dev/null awk '{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "bc" ] && DOMAIN=`host "$IP" 2>/dev/null awk '{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}'`
    [ -n "$DOMAIN" -a "$DOMAIN" = "compute-1" ] && DOMAIN=`host "$IP" 2>/dev/null awk '{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $3}'`
  fi
fi
if [ "$DOMAIN" = "$HOST" ]; then
  DOMAIN=""
elif [ -n "$DOMAIN" ]; then
  DOMAIN="/`echo $DOMAIN |tr a-z A-Z`"
  [ "$DOMAIN" = "/LOCALDOMAIN" -o "$DOMAIN" = "/LOCALHOST" ] && DOMAIN=""
fi

# alternative DNS name which is different than the hostname
[ -z "$IP" ] && IP=`hostname -i 2>/dev/null | sed 's/^::1 //;'| awk '{print $1}' | grep -v 127.0.0.1`
[ -z "$IP" -a -x /sbin/ifconfig ] && IP=`/sbin/ifconfig 2>/dev/null |awk '/inet.*(broadcast|Bcast)/ && !/127.0/{print $2}' |tail -1 | sed 's/^.*://'`
[ -z "$IP" -o "$IP" = "127.0.0.1" -o "$IP" = "127.0.1.1" ] && IP=`/sbin/ifconfig 2>/dev/null |awk '/inet.*(broadcast|Bcast)/ && !/127.0/{print $2}' |tail -1 | sed 's/^.*://'`
[ -z "$IP" -o "$IP" = "127.0.0.1" -o "$IP" = "127.0.1.1" ] && IP=`hostname -I 2>/dev/null | awk '{print $1}'`
if [ -n "$IP" ]; then
  DNS_NAME=`nslookup "$IP" 2>/dev/null |awk '/Name:|name =/{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $1}' | sed 's/[^A-Za-z0-9_-]*//g'| tail -1`
  [ -z "$DNS_NAME" ] && DNS_NAME=`host "$IP" 2>/dev/null |awk '{print $NF}' | grep -v NXDOMAIN |awk -F. '{print $1}'`

  if [ -n "$DNS_NAME" -a "$DNS_NAME" != "$HOST" -a "$DNS_NAME" != "localhost" ]; then
    DNS_NAME_LC=`echo $DNS_NAME | tr 'A-Z' 'a-z'`
    HOST_LC=`echo $HOST | tr 'A-Z' 'a-z'`
    [ "$DNS_NAME_LC" != "$HOST_LC" ] && HOST_EXTRA=" ($DNS_NAME)"
  fi
fi

[ -z "$VM" ] && VM="BareMetal"
if [ -s /sys/class/dmi/id/chassis_type ]; then
  CHASSIS_TYPE=`cat /sys/class/dmi/id/chassis_type`
  case $CHASSIS_TYPE in
    3) SYS_TYPE="Desktop"
    ;;
    4) SYS_TYPE="Low Profile Desktop"
    ;;
    5) SYS_TYPE="Pizza Box"
    ;;
    6) SYS_TYPE="Mini Tower"
    ;;
    7) SYS_TYPE="Tower"
    ;;
    8) SYS_TYPE="Portable"
    ;;
    9) SYS_TYPE="Laptop"
    ;;
    10) SYS_TYPE="Notebook"
    ;;
    11) SYS_TYPE="Hand Held"
    ;;
    12) SYS_TYPE="Docking Station"
    ;;
    13) SYS_TYPE="All in One"
    ;;
    14) SYS_TYPE="Sub Notebook"
    ;;
    15) SYS_TYPE="Space-Saving"
    ;;
    16) SYS_TYPE="Lunch Box"
    ;;
    17) SYS_TYPE="Main System Chassis"
    ;;
    18) SYS_TYPE="Expansion Chassis"
    ;;
    19) SYS_TYPE="SubChassis"
    ;;
    20) SYS_TYPE="Bus Expansion Chassis"
    ;;
    21) SYS_TYPE="Peripheral Chassis"
    ;;
    22) SYS_TYPE="Storage Chassis"
    ;;
    23) SYS_TYPE="Rack Mount"
    ;;
    24) SYS_TYPE="Sealed-Case PC"
    ;;
  esac

  # fall-back
  if [ -z "$SYS_TYPE" ]; then
    [ -f /sys/module/battery/initstate -o -d /proc/acpi/battery/BAT0 -o -L /sys/class/power_supply/BAT0 ] && SYS_TYPE="Laptop"
  fi
  [ -n "$SYS_TYPE" ] && SYS_TYPE=" $SYS_TYPE"
fi

# Tribal Knowledge:
# - all LINODE HDs are now SSD (KVM can't detect that)
if echo "$DOMAIN" | grep -qi linode; then
  if [ "$VM" = "KVM" -a "$HD_TYPE" = "HDD" ]; then
    HD_TYPE="SSD"
  fi
fi

#
# /FINAL PRINT/
#
echo "$HOST$DOMAIN$HOST_EXTRA: $OS_TYPE $OS_VERSION/$OS_YEAR$EXTRA_OS_INFO, $VM$SYS_TYPE$HW$KERNEL_TYPE, $MEM RAM, $NO_OF_CPU x $CPU_TYPE $CPU_MODEL$CPU_FREQ, $BIT_TYPE, $HD_SIZE $HD_TYPE/$FS_TYPE, Built $BUILT_FMT" |sed -e 's/\b\([A-Za-z0-9]\+\)[ ,\n]\1/\1/g; s/Linux \([A-Z][a-z]*\) Linux/\1 Linux/; s/BareMetal Notebook/Notebook/; s/BareMetal Laptop/Laptop/; s/VM Desktop/VM/; s/, Built *$//'

# clean-up
rm -f $LSCPU

# EOF
