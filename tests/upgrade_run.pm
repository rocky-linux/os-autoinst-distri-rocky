use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    my $release = lc(get_var("VERSION"));
    # NOTE: this doesn't actually work yet, it's a FIXME in fedorabase
    my $milestone = $self->get_milestone;
    my $args = "--releasever=${release}";
    # This is excessive - after the Bodhi activation point we don't
    # need --nogpgcheck for Branched. But that's hard to detect magically
    if ($release eq 'rawhide' or $milestone eq 'branched') {
        $args .= " --nogpgcheck";
    }
    # disable screen blanking (download can take a long time)
    script_run "setterm -blank 0";

    assert_script_run "dnf -y system-upgrade download ${args}", 6000;

    upload_logs "/var/log/dnf.log";
    upload_logs "/var/log/dnf.rpm.log";

    script_run "dnf system-upgrade reboot";
    # fail immediately if we see a DNF error message
    die "DNF reported failure" if (check_screen "upgrade_fail");
    # try and catch if we hit RHBZ #1349721 and work around it
    if (check_screen "bootloader") {
        # wait some secs for the screen to clear
        sleep 10;
        if (check_screen "bootloader") {
            record_soft_failure;
            $self->do_bootloader(postinstall=>1, params=>"enforcing=0");
        }
    }
}


sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
