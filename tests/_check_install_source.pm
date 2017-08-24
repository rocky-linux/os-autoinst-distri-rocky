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
        $repourl =~ s/^nfsvers=.://;
        # the above both checks if we're dealing with an NFS URL, and
        # strips the 'nfs:' and 'nfsvers=.:' from it if so
	if (get_var("OFW")) {
            # for PowerPC mounting info may be not in anaconda.log
            assert_script_run "mount |grep nfs |grep '${repourl}'";
	}
	else {
            # message is in packaging.log up to F26, anaconda.log F27+
            assert_script_run "grep 'mounting ${repourl}' /tmp/packaging.log /tmp/anaconda.log";
	}
    }
    else {
        assert_script_run "grep \"added repo: 'anaconda'.*${repourl}\" /tmp/packaging.log";
    }
    send_key "ctrl-alt-f6";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 30; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
