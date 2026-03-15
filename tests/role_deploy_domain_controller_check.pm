use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run {
    my $self = shift;
    # make sure ipa.service actually came up successfully
    my $count = 40;
    while (1) {
        $count -= 1;
        die "Waited too long for ipa.service to show up!" if ($count == 0);
        sleep 3;
        # if it's active, we're done here
        last unless script_run 'systemctl is-active ipa.service';
        # if it's not...fail if it's failed
        assert_script_run '! systemctl is-failed ipa.service';
        # if we get here, it's activating, so loop around
    }
    # if this is an update, notify clients that we're now up again
    mutex_create('server_upgraded') if get_var("UPGRADE");
    # once child jobs are done, stop the server
    wait_for_children;
    # run post-fail hook to upload logs - even when this test passes
    # there are often cases where we need to see the logs (e.g. client
    # test failed due to server issue)
    $self->post_fail_hook();
    assert_script_run 'systemctl stop ipa.service';
    # check server is stopped
    assert_script_run '! systemctl is-active ipa.service';
    # decommission the server
    assert_script_run 'ipa-server-install -U --uninstall', 300;
    # try and un-garble the screen that the above sometimes garbles
    # ...we may be on tty1 or tty3 now, so flip between them
    select_console "tty1-console";
    select_console "tty3-console";
    # FIXME check server is decommissioned...how?
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
