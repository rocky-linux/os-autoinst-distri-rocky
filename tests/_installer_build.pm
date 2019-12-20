use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
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
    unless (get_var("DEVELOPMENT")) {
        $cmd .= " --isfinal --repo=/etc/yum.repos.d/fedora-updates.repo";
    }
    $cmd .= " --repo=/etc/yum.repos.d/advisory.repo ./results";
    assert_script_run $cmd, 1500;
    assert_script_run "mv results/images/boot.iso ./${advortask}-netinst-${arch}.iso";
    upload_asset "./${advortask}-netinst-x86_64.iso";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
