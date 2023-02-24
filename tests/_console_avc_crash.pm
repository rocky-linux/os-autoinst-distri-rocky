use base "installedtest";
use strict;
use utils;
use testapi;

sub run {
    my $self = shift;
    $self->root_console(tty => 3);
    # if this is a non-English, non-switched layout, load US layout
    # at this point
    # FIXME: this is all kind of a mess, as on such configs we need
    # native layout to log in to a console but US layout to type
    # anything at a console. the more advanced upstream 'console'
    # handling may help us here if we switch to it
    console_loadkeys_us;
    # check there are no AVCs. We expect an error here: if we don't
    # get an error, it means there *are* AVCs.
    my $hook_run = 0;
    unless (script_run 'ausearch -m avc -ts yesterday > /tmp/avcs.txt 2>&1') {
        record_soft_failure "AVC(s) found (see avcs.txt log)";
        upload_logs "/tmp/avcs.txt";
        # Run the post-fail hook so we have all the logs
        $self->post_fail_hook();
        $hook_run = 1;
    }
    # check there are no crashes. Similarly expect an error here
    unless (script_run 'coredumpctl list > /tmp/coredumps.txt 2>&1') {
        record_soft_failure "Crash(es) found (see coredumps.txt log)";
        upload_logs "/tmp/coredumps.txt";
        $self->post_fail_hook() unless ($hook_run);
    }
}

sub test_flags {
    return {};
}

1;

# vim: set sw=4 et:
