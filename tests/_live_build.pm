use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
    my $advortask = get_var("ADVISORY_OR_TASK");
    my $arch = get_var("ARCH");
    my $subv = get_var("SUBVARIANT");
    my $lcsubv = lc($subv);
    if (get_var("NUMDISKS") > 2) {
        # put /var/lib/mock on the third disk, so we don't run out of
        # space on the main disk. The second disk will have already
        # been claimed for the update repo.
        assert_script_run "echo 'type=83' | sfdisk /dev/vdc";
        assert_script_run "mkfs.ext4 /dev/vdc1";
        assert_script_run "echo '/dev/vdc1 /var/lib/mock ext4 defaults 1 2' >> /etc/fstab";
        assert_script_run "mkdir -p /var/lib/mock";
        assert_script_run "mount /var/lib/mock";
    }
    # install the tools we need
    assert_script_run "dnf -y install mock git pykickstart tar", 120;
    # base mock config on original
    assert_script_run "echo \"include('/etc/mock/fedora-${version}-${arch}.cfg')\" > /etc/mock/openqa.cfg";
    # make the side and workarounds repos and the serial device available inside the mock root
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_enable\'] = True" >> /etc/mock/openqa.cfg';
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/opt/update_repo\', \'/opt/update_repo\'))" >> /etc/mock/openqa.cfg';
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/opt/workarounds_repo\', \'/opt/workarounds_repo\'))" >> /etc/mock/openqa.cfg';
    assert_script_run 'echo "config_opts[\'plugin_conf\'][\'bind_mount_opts\'][\'dirs\'].append((\'/dev/' . $serialdev . '\', \'/dev/' . $serialdev . '\'))" >> /etc/mock/openqa.cfg';
    # add the side repo and workarounds to the config
    assert_script_run 'printf "config_opts[\'dnf.conf\'] += \"\"\"\n[advisory]\nname=Advisory repo\nbaseurl=file:///opt/update_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n\n[workarounds]\nname=Workarounds repo\nbaseurl=file:///opt/workarounds_repo\nenabled=1\nmetadata_expire=3600\ngpgcheck=0\n\"\"\"" >> /etc/mock/openqa.cfg';
    # replace metalink with mirrorlist so we don't get slow mirrors
    repos_mirrorlist("/etc/mock/openqa.cfg");
    # upload the config so we can check it's OK
    upload_logs "/etc/mock/openqa.cfg";
    # now check out the kickstarts
    assert_script_run 'git clone https://pagure.io/fedora-kickstarts.git';
    assert_script_run 'cd fedora-kickstarts';
    assert_script_run "git checkout f${version}";
    # now add the side repo to fedora-repo-not-rawhide.ks
    assert_script_run 'echo "repo --name=advisory --baseurl=file:///opt/update_repo" >> fedora-repo-not-rawhide.ks';
    # and the workarounds repo
    assert_script_run 'echo "repo --name=workarounds --baseurl=file:///opt/workarounds_repo" >> fedora-repo-not-rawhide.ks';
    # now flatten the kickstart
    assert_script_run "ksflatten -c fedora-live-${lcsubv}.ks -o openqa.ks";
    # upload the kickstart so we can check it
    upload_logs "openqa.ks";
    # now install the tools into the mock
    assert_script_run "mock -r openqa --isolation=simple --install bash coreutils glibc-all-langpacks lorax-lmc-novirt selinux-policy-targeted shadow-utils util-linux", 300;
    # now make the image build directory inside the mock root and put the kickstart there
    assert_script_run 'mock -r openqa --isolation=simple --chroot "mkdir -p /chroot_tmpdir"';
    assert_script_run "mock -r openqa --isolation=simple --copyin openqa.ks /chroot_tmpdir";
    # PULL SOME LEVERS! PULL SOME LEVERS!
    assert_script_run "mock -r openqa --enable-network --isolation=simple --chroot \"/sbin/livemedia-creator --ks /chroot_tmpdir/openqa.ks --logfile /chroot_tmpdir/lmc-logs/livemedia-out.log --no-virt --resultdir /chroot_tmpdir/lmc --project Fedora-${subv}-Live --make-iso --volid FWL-${advortask} --iso-only --iso-name Fedora-${subv}-Live-${arch}-${advortask}.iso --releasever ${version} --macboot\"", 3600;
    unless (script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc-logs/livemedia-out.log .") {
        upload_logs "livemedia-out.log";
    }
    unless (script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc-logs/anaconda/ anaconda") {
        assert_script_run "tar cvzf anaconda.tar.gz anaconda/";
        upload_logs "anaconda.tar.gz";
    }
    assert_script_run "mock -r openqa --isolation=simple --copyout /chroot_tmpdir/lmc/Fedora-${subv}-Live-${arch}-${advortask}.iso .";
    upload_asset "./Fedora-${subv}-Live-${arch}-${advortask}.iso";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
