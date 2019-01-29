use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    my $version = get_var("VERSION");
    my $advortask = get_var("ADVISORY_OR_TASK");
    my $arch = get_var("ARCH");
    # we need lorax from u-t for f28 atm it seems
    my $loraxcmd = "dnf -y ";
    $loraxcmd .= "--enablerepo=updates-testing " if (get_var("VERSION") eq "28");
    $loraxcmd .= "install lorax";
    assert_script_run $loraxcmd, 90;
    # this 'temporary file cleanup' thing can actually wipe bits of
    # the lorax install root while lorax is still running...
    assert_script_run "systemctl stop systemd-tmpfiles-clean.timer";
    # dracut-fips doesn't exist any more; this breaks f28 builds as
    # it *did* exist when f28 came out, so lorax tries to use
    # dracut-fips from the frozen release repo with newer lorax from
    # the updates repo which obsoletes it, and gets confused
    assert_script_run 'sed -i -e "s,dracut-fips,,g" /usr/share/lorax/templates.d/99-generic/runtime-install.tmpl';
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
