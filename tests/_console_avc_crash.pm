use base "installedtest";
use strict;
use utils;
use testapi;

sub run {
    my $self = shift;
    $self->root_console(tty=>3);
    # if this is a non-English, non-switched layout, load US layout
    # at this point
    # FIXME: this is all kind of a mess, as on such configs we need
    # native layout to log in to a console but US layout to type
    # anything at a console. the more advanced upstream 'console'
    # handling may help us here if we switch to it
    console_loadkeys_us;
    # check there are no AVCs. We expect an error here: if we don't
    # get an error, it means there *are* AVCs.
    record_soft_failure "AVC(s) found" unless (script_run 'ausearch -m avc -ts yesterday 2>&1');
    # check there are no crashes. Similarly expect an error here
    record_soft_failure "Crash(es) found" unless (script_run 'coredumpctl list 2>&1');
}

sub test_flags {
    return {};
}

1;

# vim: set sw=4 et:
