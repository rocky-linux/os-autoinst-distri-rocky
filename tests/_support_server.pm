use base "installedtest";
use strict;
use anaconda;
use testapi;
use lockapi;
use mmapi;
use tapnet;
use utils;

sub _pxe_setup {
    # This happens before local DNS server is running and dnf will fail. Temporarily add 8.8.8.8 to resolve.conf
    assert_script_run "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf";

    # set up PXE server (via dnsmasq). Not used for update tests.
    # don't get hung up on slow mirrors when DNFing...
    repos_mirrorlist;
    # create necessary dirs
    assert_script_run "mkdir -p /var/lib/tftpboot/rocky";
    # basic tftp config
    assert_script_run "printf 'enable-tftp\ntftp-root=/var/lib/tftpboot\ntftp-secure\n' >> /etc/dnsmasq.conf";
    # pxe boot config
    # we boot grub directly not shim on aarch64 as shim fails to boot
    # with 'Synchronous Exception'
    # https://bugzilla.redhat.com/show_bug.cgi?id=1592148
    assert_script_run "printf 'dhcp-match=set:efi-x86_64,option:client-arch,7\ndhcp-match=set:efi-x86_64,option:client-arch,9\ndhcp-match=set:bios,option:client-arch,0\ndhcp-match=set:efi-aarch64,option:client-arch,11\ndhcp-match=set:ppc64,option:client-arch,12\ndhcp-match=set:ppc64,option:client-arch,13\ndhcp-boot=tag:efi-x86_64,\"shim.efi\"\ndhcp-boot=tag:bios,\"pxelinux.0\"\ndhcp-boot=tag:efi-aarch64,\"grubaa64.efi\"\ndhcp-boot=tag:ppc64,\"boot/grub2/powerpc-ieee1275/core.elf\"\n' >> /etc/dnsmasq.conf";
    # install and configure bootloaders
    my $ourversion = get_var("CURRREL");
    my $testversion = get_var("RELEASE");
    assert_script_run "mkdir -p /var/tmp/rocky";
    my $arch = get_var("ARCH");

    if ($arch eq 'x86_64') {
        # x86_64: use syslinux for BIOS, grub2 with 'linuxefi' for UEFI
        assert_script_run "mkdir -p /var/lib/tftpboot/pxelinux.cfg";
        # install bootloader packages
        assert_script_run "dnf -y install syslinux", 120;
        assert_script_run "rpm --root=/var/tmp/rocky --rebuilddb", 60;
        assert_script_run "cd /var/tmp; dnf download rocky-release rocky-repos rocky-gpg-keys", 60;
        assert_script_run "rpm --root=/var/tmp/rocky --nodeps -i /var/tmp/*.rpm", 60;
        #assert_script_run "sed -i /var/tmp/rocky/etc/yum.repos.d/Rocky-*.repo -e 's/repo=/repo=rocky-/g'", 60;
        assert_script_run "dnf -y --releasever=$ourversion --refresh --installroot=/var/tmp/rocky install shim-x64 grub2-efi-x64", 1800;

        # copy bootloader files to tftp root
        assert_script_run "cp /usr/share/syslinux/{pxelinux.0,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} /var/lib/tftpboot";
        assert_script_run "cp /var/tmp/rocky/boot/efi/EFI/rocky/{shimx64.efi,shimx64-rocky.efi,grubx64.efi} /var/lib/tftpboot";
        # bootloader configs
        # BIOS
        assert_script_run "printf 'default vesamenu.c32\nprompt 1\ntimeout 600\n\nlabel linux\n  menu label ^Install Rocky Linux 64-bit\n  menu default\n  kernel rocky/vmlinuz\n  append initr
d=rocky/initrd.img inst.ks=file:///ks.cfg ip=dhcp\nlabel local\n  menu label Boot from ^local drive\n  localboot 0xffff\n' >> /var/lib/tftpboot/pxelinux.cfg/default";
        # UEFI
        assert_script_run "printf 'function load_video {\n  insmod efi_gop\n  insmod efi_uga\n  insmod ieee1275_fb\n  insmod vbe\n  insmod vga\n  insmod video_bochs\n  insmod video_cirrus\n}\
n\nload_video\nset gfxpayload=keep\ninsmod gzio\n\nmenuentry \"Install Rocky Linux 64-bit\"  --class rocky --class gnu-linux --class gnu --class os {\n  linuxefi rocky/vmlinuz ip=dhcp inst.ks=
file:///ks.cfg\n  initrdefi rocky/initrd.img\n}' >> /var/lib/tftpboot/grub.cfg";
        # DEBUG DEBUG
        upload_logs "/etc/dnsmasq.conf";
        upload_logs "/var/lib/tftpboot/grub.cfg";
        upload_logs "/var/lib/tftpboot/pxelinux.cfg/default";
    }

    elsif ($arch eq 'ppc64le') {
        # ppc64le: use grub2 for OFW
        # install bootloader tools package
        assert_script_run "dnf -y install grub2-tools-extra", 360;
        # install a network bootloader to tftp root
        assert_script_run "grub2-mknetdir --net-directory=/var/lib/tftpboot";
        # bootloader config
        assert_script_run "printf 'set default=0\nset timeout=5\n\nmenuentry \"Install Rocky Linux\"  --class rocky --class gnu-linux --class gnu --class os {\n  linux rocky/vmlinuz ip=dhcp inst.ks=file:///ks.cfg\n  initrd rocky/initrd.img\n}' >> /var/lib/tftpboot/boot/grub2/grub.cfg";
        # DEBUG DEBUG
        upload_logs "/etc/dnsmasq.conf";
        upload_logs "/var/lib/tftpboot/boot/grub2/grub.cfg";
    }

    elsif ($arch eq 'aarch64') {
        # aarch64: use grub2 with 'linux' for UEFI
        # copy bootloader files to tftp root (we just use the system
        # bootloader, no need to install packages)
        assert_script_run "cp /boot/efi/EFI/rocky/{shim.efi,grubaa64.efi} /var/lib/tftpboot";
        # bootloader config
        assert_script_run "printf 'function load_video {\n  insmod efi_gop\n  insmod efi_uga\n  insmod ieee1275_fb\n  insmod vbe\n  insmod vga\n  insmod video_bochs\n  insmod video_cirrus\n}\n\nload_video\nset gfxpayload=keep\ninsmod gzio\n\nmenuentry \"Install Rocky Linux\"  --class rocky --class gnu-linux --class gnu --class os {\n  linux rocky/vmlinuz ip=dhcp inst.ks=file:///ks.cfg\n  initrd rocky/initrd.img\n}' >> /var/lib/tftpboot/grub.cfg";
        # DEBUG DEBUG
        upload_logs "/etc/dnsmasq.conf";
        upload_logs "/var/lib/tftpboot/grub.cfg";
    }

    # download kernel and initramfs
    my $location = get_var("LOCATION");
    my $kernpath = "images/pxeboot";
        # for some crazy reason these are in a different place for ppc64
    $kernpath = "ppc/ppc64" if ($arch eq 'ppc64le');
    assert_script_run "curl -o /var/lib/tftpboot/rocky/vmlinuz $location/BaseOS/${arch}/os/${kernpath}/vmlinuz";
    assert_script_run "curl -o /var/lib/tftpboot/rocky/initrd.img $location/BaseOS/${arch}/os/${kernpath}/initrd.img";
    # get a kickstart to embed in the initramfs, for testing:
    # https://fedoraproject.org/wiki/QA:Testcase_Kickstart_File_Path_Ks_Cfg
    assert_script_run "curl -o ks.cfg https://git.rockylinux.org/tcooper/kickstarts/-/raw/main/root-user-crypted-net.ks";
    # tweak the repo config in it
    assert_script_run "sed -i -e 's,^url.*,nfs --server=nfs://172.16.2.110 --dir=/repo --opts=nfsver=4,g' ks.cfg";
    # embed it
    assert_script_run "echo ks.cfg | cpio -c -o >> /var/lib/tftpboot/rocky/initrd.img";
    # chown root
    assert_script_run "chown -R dnsmasq /var/lib/tftpboot";
    assert_script_run "restorecon -vr /var/lib/tftpboot";
    # open firewall ports
    assert_script_run "firewall-cmd --add-service=tftp";
}

sub run {
    my $self=shift;
    # disable systemd-resolved, it conflicts with dnsmasq
    unless (script_run "systemctl is-active systemd-resolved.service") {
        script_run "systemctl stop systemd-resolved.service";
        script_run "systemctl disable systemd-resolved.service";
        script_run "rm -f /etc/resolv.conf";
        script_run "systemctl restart NetworkManager";
    }
    ## DNS / DHCP (dnsmasq)
    # create config
    assert_script_run "printf 'domain=test.openqa.fedoraproject.org\ndhcp-range=172.16.2.150,172.16.2.199\ndhcp-option=option:router,172.16.2.2\n' > /etc/dnsmasq.conf";
    # do PXE setup if this is not an update test
    _pxe_setup() unless (get_var("ADVISORY_OR_TASK"));
    # open firewall ports
    assert_script_run "firewall-cmd --add-service=dhcp";
    assert_script_run "firewall-cmd --add-service=dns";
    # start server
    assert_script_run "systemctl restart dnsmasq.service";
    assert_script_run "systemctl is-active dnsmasq.service";

    ## ISCSI

    # start up iscsi target
    #assert_script_run "printf '<target iqn.2016-06.local.domain:support.target1>\n    backing-store /dev/vdb\n    incominguser test weakpassword\n</target>' > /etc/tgt/conf.d/openqa.conf";
    assert_script_run "targetcli /backstores/block create dev=/dev/vdb name=vdb";
    assert_script_run "targetcli /iscsi create wwn=iqn.2016-06.local.domain:support.target1";
    assert_script_run "targetcli /iscsi/iqn.2016-06.local.domain:support.target1/tpg1 set auth userid=test password=weakpassword";
    assert_script_run "targetcli /iscsi/iqn.2016-06.local.domain:support.target1/tpg1/luns create /backstores/block/vdb";
    # open firewall port
    assert_script_run "firewall-cmd --add-port=3260/tcp";
    assert_script_run "systemctl restart target.service";
    assert_script_run "systemctl is-active target.service";

    ## NFS

    # create the file share
    assert_script_run "mkdir -p /export";
    # get the kickstart
    assert_script_run "curl -o /export/root-user-crypted-net.ks https://fedorapeople.org/groups/qa/kickstarts/root-user-crypted-net.ks";
    # for update tests, set up the update repository and export it
    if (get_var("ADVISORY_OR_TASK")) {
        assert_script_run "echo '/opt/update_repo 172.16.2.0/24(ro)' >> /etc/exports";
    }
    # for compose tests, we do all this stuff
    else {
        # create the repo share
        assert_script_run "mkdir -p /repo";
        # create a mount point for the ISO
        assert_script_run "mkdir -p /mnt/iso";
        # mount the ISO there
        assert_script_run "mount /dev/cdrom /mnt/iso";
        # copy the contents of the ISO to the repo share
        assert_script_run "dnf -y install rsync", 180;
        assert_script_run "rsync -av /mnt/iso/ /repo", 360;
        # put the updates image in the NFS repo (for testing this update
        # image delivery method)
        assert_script_run "curl -o /repo/images/updates.img https://fedorapeople.org/groups/qa/updates/updates-openqa.img";
        # create the iso share
        assert_script_run "mkdir -p /iso";
        # recreate an iso file
        copy_devcdrom_as_isofile('/iso/image.iso');
        # set up the exports
        assert_script_run "printf '/export 172.16.2.0/24(ro)\n/repo 172.16.2.0/24(ro)\n/iso 172.16.2.0/24(ro)' > /etc/exports";
    }

    # open firewall port
    assert_script_run "firewall-cmd --add-service=nfs";
    # start the server
    assert_script_run "systemctl restart nfs-server.service";
    assert_script_run "systemctl is-active nfs-server.service";

    # report ready, wait for children
    mutex_create('support_ready');
    wait_for_children;
    # upload logs in case of child failures
    $self->post_fail_hook();
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
