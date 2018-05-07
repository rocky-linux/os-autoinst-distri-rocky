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
        # there are only three hard problems in software development:
        # naming things, cache expiry, off-by-one errors...and quoting
        # we need single quotes (at the perl level) around the start
        # of this, so the backslashes are not interpreted by perl but
        # passed through to ultimately be interpreted by 'grep'
        # itself. We need double quotes around $repourl so that *is*
        # interpreted by perl. And we need quotes around the entire
        # expression at the bash level, and single quotes around the
        # text 'anaconda' at the level of grep, as the string we're
        # actually matching on literally has 'anaconda' in it. We need
        # (added|enabled) till F28 goes EOL: the log line was changed
        # in Rawhide after F28 came out.
        assert_script_run 'grep "\(added\|enabled\) repo: ' . "'anaconda'.*${repourl}" . '" /tmp/packaging.log';
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
