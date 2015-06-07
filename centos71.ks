#version=DEVEL
text
skipx

repo --name="repo0" --baseurl=http://mirrors.kernel.org/centos/7/os/x86_64
repo --name="repo1" --baseurl=http://mirrors.kernel.org/centos/7/updates/x86_64
repo --name="repo2" --baseurl=http://mirrors.kernel.org/fedora-epel/7/x86_64
repo --name="repo3" --baseurl=https://repos.fedorapeople.org/repos/openstack/openstack-juno/epel-7

# Firewall configuration
firewall --enabled --service=ssh
# Root password
rootpw --iscrypted --lock $6$NdayUKYBuM8nG2bj$srJWOWi6wIiEWFaYBg08QnqiCgwQbno4uefHFQv8DZQ8924yXSs0s8GrT0dBk4xgSnD2DRyXQRs9k9xWmKysg1
# System authorization information
auth --useshadow --passalgo=sha512
# System keyboard
keyboard uk
# System language
lang en_GB.UTF-8
# SELinux configuration
selinux --permissive
# Installation logging level
logging --level=info
# Reboot after installation
reboot
# System services
services --disabled="avahi-daemon,iscsi,iscsid,firstboot,kdump" --enabled="network,sshd,rsyslog,tuned"
# System timezone
timezone --isUtc Europe/London
# Network information
network  --bootproto=dhcp --device=eth0 --onboot=on
# System bootloader configuration
bootloader --append="console=ttyS0,115200n8 console=tty0" --location=mbr --driveorder="sda" --timeout=1
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="xfs" --size=2048
part swap --size=2048

%post --erroronfail

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

cat <<EOL >> /etc/rc.local
if [ ! -d /root/.ssh ] ; then
    mkdir -p /root/.ssh
    chmod 0700 /root/.ssh
    restorecon /root/.ssh
fi
EOL

cat <<EOL >> /etc/ssh/sshd_config
UseDNS no
PermitRootLogin without-password
EOL

# bz705572
ln -s /boot/grub/grub.conf /etc/grub.conf

# bz688608
sed -i 's|\(^PasswordAuthentication \)yes|\1no|' /etc/ssh/sshd_config

# allow sudo powers to cloud-user
echo -e 'cloud-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# bz983611
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tune-profiles/active-profile

#bz 1011013
# set eth0 to recover from dhcp errors
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

#bz912801
# prevent udev rules from remapping nics
touch /etc/udev/rules.d/75-persistent-net-generator.rules

#setup getty on ttyS0
echo "ttyS0" >> /etc/securetty
cat <<EOF > /etc/init/ttyS0.conf
start on stopped rc RUNLEVEL=[2345]
stop on starting runlevel [016]
respawn
instance /dev/ttyS0
exec /sbin/agetty /dev/ttyS0 115200 vt100-nav
EOF

# lock root password
passwd -d root
passwd -l root

# clean up installation logs"
yum clean all
rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*
%end

%packages --nobase
acpid
attr
audit
authconfig
basesystem
bash
cloud-init
coreutils
cpio
cronie
device-mapper
dhclient
dracut
e2fsprogs
efibootmgr
filesystem
glibc
grub2
heat-cfntools
initscripts
iproute
iptables
iptables-ipv6
iputils
kbd
kernel
kpartx
ncurses
net-tools
nfs-utils
openssh-clients
openssh-server
parted
passwd
policycoreutils
procps
rootfiles
rpm
rsync
rsyslog
screen
selinux-policy
selinux-policy-targeted
sendmail
setup
shadow-utils
sudo
syslinux
tar
tuned
util-linux-ng
vim-enhanced
yum
yum-metadata-parser
-*-firmware
-NetworkManager
-b43-openfwwf
-biosdevname
-fprintd
-fprintd-pam
-gtk2
-libfprint
-mcelog
-plymouth
-redhat-support-tool
-system-config-*
-wireless-tools

wget

%end
