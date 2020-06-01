# HW-Info
Portable &amp; simple HW-Info script - quickly &amp; easily get an idea of the HW you're working on (Linux, MacOS, Windows, Chromebook, etc)

## Description
Provides the following information as a 1-liner:
- hostname (and domain, if appropriate)
- OS type & OS name (eg: Ubuntu) and version
- Distribution name (or MacOS release friendly name)
- year of OS release
- Bare Metal or VM, VM type
- HW type & model (incl hypervisor type)
- How much RAM (in GB)
- How many CPUs (or cores/threads)
- Real or virtual CPUs? (CPUs vs vCPUs)
- CPU model/type and CPU speed (in GHz)
- CPU Architecture (eg: Haswell, Skylake, Ice Lake, etc)
- 32bit or 64bit system?
- Local Disk sizes (in human friendly format)
- Is it a HDD (rotational/spinning disk/media) or SSD (flash) disk (or NVMe SSD)
- FS type (eg: ext4, ntfs, btrfs)
- When was the OS built? (based on dates of some key root files)

## How to run directly
You can run this directly from GitHub:

`$ curl -s https://raw.githubusercontent.com/kordianw/HW-Info/master/hw-info.sh | bash`

## Examples
Examples on running on various Operating Systems:

`$ ./hw-info.sh`

#### Linux (Ubuntu, RHEL & Mint):
`speedy: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, KVM: pc-q35-3.1 QEMU Standard PC (Q35+ICH9, 2009), 4GB RAM, 2 x vCPU E5-2680 v3 @ 2.50GHz, 64bit, 77.2G+2.5G Disk/ext4, Built Apr'14`

`kw-rhel74/LAB: Linux RHEL 7.4/'17, VMware, 8GB RAM, 4 x vCPU E5-2697 v2 @ 2.70GHz, 64bit, 20G Disk/xfs, Built Oct'17`

`laptop-pc (t480s): Linux Mint 19.3 Tricia/'19, BareMetal: Lenovo ThinkPad T480s, 15GB RAM, 8 x CPU i7-8650U @ 1.90GHz, 64bit, 119.5G Disk/overlay, Built Aug'07`

#### MacOS (Darwin)
`maccy/LCL: MacOS (Darwin) macOS 10.13.6/'20 (High Sierra), BareMetal: MacBook Air (13-inch, Early 2014), 8GB RAM, 4 x CPU i5-4260U @ 1.40GHz, 64bit, 251G Disk/apfs, Built '19`

`macbook12: MacOS (Darwin) macOS 10.12.6/'19 (Sierra), BareMetal: MacBook (Retina, 12-inch, Early 2016), 8GB RAM, 4 x CPU m5-6Y54 @ 1.10GHz, 64bit, 500G Disk/hfs, Built '19`

#### Windows (via WSL - Windows Subsystem for Linux)
`DESKTOP-GTTHH7U: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'19, WSL/container, 4GB RAM, 1 x vCPU i7-6700 @ 3.40GHz, 64bit, 50G Disk/lxfs, Built Apr'20`

#### Public Cloud - AWS / GCP / Azure
`ip-172-31-44-12/EC2: Amazon Linux 2/'20, Xen VM: 4.2.amazon HVM, 1GB RAM, 1 x vCPU E5-2676 v3 @ 2.40GHz (Haswell), 64bit, 8G Disk/xfs, Built Apr'20`

`ip-172-31-39-11/EC2: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, Xen VM: 4.2.amazon HVM, 1GB RAM, 1 x vCPU E5-2676 v3 @ 2.40GHz (Haswell), 64bit, 7.7G Disk/ext4, Built Apr'20`

`ip-172-31-11-25/EC2: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, KVM: Amazon EC2 c5n.large, 5GB RAM, 2 x vCPU Xeon Platinum 8124M @ 3.00GHz (Skylake'15), 64bit, 8G Disk/ext4, Built Apr'20`


`debian-gcp/US-EAST1-B: Linux Debian 9 Stretch/'20, KVM: Google Compute Engine, 612MB RAM, 1 x vCPU @ 2.30GHz, 64bit, 30G Disk/ext4, Built Apr'20`

`ubuntu-gcp/US-EAST1-B: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, KVM: Google Compute Engine, 575MB RAM, 1 x vCPU @ 2.00GHz (Skylake), 64bit, 10G Disk/ext4, Built Apr'20`


`ubuntu-azure: Linux Ubuntu 18.04.4 LTS Bionic Beaver/'20, Hyper-V/VM: Hyper-V Microsoft VM, 1GB RAM, 1 x vCPU E5-2673 v4 @ 2.30GHz (Broadwell), 64bit, 30G+4G Disk/ext4, Built Apr'20`

#### Chrome OS (via Chromebook Linux Shell):
`penguin: Linux Debian 9 Stretch/'20, KVM: ChromiumOS crosvm, 3GB RAM, 2 x vCPU 06/4c 1.6GHz, 64bit, 7.7G Disk/btrfs, Built Feb'20`

#### Cygwin (Windows):
`Speedy-PC: Cygwin 3.0.7/'19, BareMetal: Dell XPS 8900, 32GB RAM, 8 x CPU i7-6700 @ 3.40GHz, 32bit, 477G+932G+7.3T Disk/ntfs, Built Sep'17`

#### Raspbian (Raspberry Pi):
`pi-hole: Linux Raspbian 9 Stretch/'19, BareMetal: RaspberryPi 3 B+ Rev 1.3, 1GB RAM, 4 x CPU ARMv7 Rev4 (v7l) 1.4GHz, 59.6G Disk/ext4, Built Nov'18`
