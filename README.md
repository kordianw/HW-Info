# HW-Info
Portable &amp; simple HW-Info script - quickly &amp; easily get an idea of the HW you're working on (Linux, MacOS, etc)

## Description
Provides the following information as a 1-line in CSV format:
- hostname (and domain)
- OS type
- OS name (eg: Ubuntu) and version
- Distribution name (or MacOS release friendly name)
- year of OS release
- Bare Metal or VM
- HW type & model
- How much RAM (in GB)
- How many CPUs (or cores/threads)
- Real or virtual CPUs? (CPUs vs vCPUs)
- CPU model/type and CPU speed (in GHz)
- 32bit or 64bit system?
- Local Disk sizes (in human friendly format)
- FS type (eg: ext4, ntfs)
- When was the OS built? (based on dates of some key root files)

## Examples
Examples on running on various Operating Systems:

`$ ./hw-info.sh`

#### Linux (Ubuntu, RHEL & Mint):
`speedy: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, KVM: pc-q35-3.1 QEMU Standard PC (Q35+ICH9, 2009), 4GB RAM, 2 x vCPU E5-2680 v3 @ 2.50GHz, 64bit, 77.2G+2.5G Disk/ext4, Built Apr'14`

`kw-rhel74/LAB: Linux RHEL 7.4/'17, VMware, 8GB RAM, 4 x vCPU E5-2697 v2 @ 2.70GHz, 64bit, 20G Disk/xfs, Built Oct'17`

`laptop-pc (t480s): Linux Mint 19.3 Tricia/'19, BareMetal: Lenovo ThinkPad T480s, 15GB RAM, 8 x CPU i7-8650U @ 1.90GHz, 64bit, 119.5G Disk/overlay, Built Aug'07`

#### MacOS (Darwin)
`maccy/LCL: MacOS (Darwin) macOS 10.13.6/'20, BareMetal: MacBook Air (13-inch, Early 2014), 8GB RAM, 4 x CPU i5-4260U @ 1.40GHz, 64bit, 251GB Disk/apfs, Built '19`

#### Cygwin (Windows):
`Speedy-PC: Cygwin 3.0.7/'19, BareMetal: Dell XPS 8900, 32GB RAM, 8 x CPU i7-6700 @ 3.40GHz, 32bit, 477G+932G+7.3T Disk/ntfs, Built Sep'17`

#### Chrome OS (Chromebook Linux Shell):
`penguin: Linux Debian 9 Stretch/'20, KVM: ChromiumOS crosvm, 3GB RAM, 2 x vCPU 06/4c 1.6GHz, 64bit, 7.7G Disk/btrfs, Built Feb'20`

#### Raspbian:
`pi-hole: Linux Raspbian 9 Stretch/'19, BareMetal: RaspberryPi 3 B+ Rev 1.3, 1GB RAM, 4 x CPU ARMv7 Rev4 (v7l) 1.4GHz, 59.6G Disk/ext4, Built Nov'18`
