use base "anacondatest";
use strict;
use testapi;
use anaconda;

sub run {
    my $self = shift;
    my $repourl;
    if (get_var("MIRRORLIST_GRAPHICAL")) {
        $repourl = get_mirrorlist_url();
    }
    else {
        $repourl = get_var("REPOSITORY_VARIATION", get_var("REPOSITORY_GRAPHICAL"));
        $repourl = get_full_repo($repourl);
    }

    # check that the repo was used
    $self->root_console;
    if ($repourl =~ s/^nfs://) {
        # the above both checks if we're dealing with an NFS URL, and
        # strips the 'nfs:' from it if so
        assert_script_run "grep 'mounting ${repourl}' /tmp/packaging.log";
    }
    else {
        assert_script_run "grep \"added repo: 'anaconda'.*${repourl}\" /tmp/packaging.log";
    }
    send_key "ctrl-alt-f6";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 30; #

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
