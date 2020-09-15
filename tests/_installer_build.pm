use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
    my $currrel = get_var("CURRREL");
    my $advortask = get_var("ADVISORY_OR_TASK");
    my $arch = get_var("ARCH");
    assert_script_run "dnf -y install lorax", 90;
    # this 'temporary file cleanup' thing can actually wipe bits of
    # the lorax install root while lorax is still running...
    assert_script_run "systemctl stop systemd-tmpfiles-clean.timer";
    assert_script_run "mkdir -p /root/imgbuild";
    assert_script_run "pushd /root/imgbuild";
    assert_script_run "setenforce Permissive";
    my $cmd = "lorax -p Fedora -v ${version} -r ${version} --repo=/etc/yum.repos.d/fedora.repo";
    # rootfs in F30 installer images seems to have got very big at
    # some point, let's work around that for now:
    # https://bodhi.fedoraproject.org/updates/FEDORA-2020-1070052d10#comment-1284223
    $cmd .= " --rootfs-size 3" if ($version eq 30);
    unless ($version > $currrel) {
        $cmd .= " --isfinal --repo=/etc/yum.repos.d/fedora-updates.repo";
    }
    $cmd .= " --repo=/etc/yum.repos.d/advisory.repo --repo=/etc/yum.repos.d/workarounds.repo ./results";
    assert_script_run $cmd, 1500;
    assert_script_run "mv results/images/boot.iso ./${advortask}-netinst-${arch}.iso";
    upload_asset "./${advortask}-netinst-x86_64.iso";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
