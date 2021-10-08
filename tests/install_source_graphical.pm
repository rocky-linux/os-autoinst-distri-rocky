use base "anacondatest";
use strict;
use testapi;
use utils;
use anaconda;
use Time::HiRes qw( usleep );

sub run {
    my $self = shift;
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Go into the Install Source spoke
    assert_and_click "anaconda_main_hub_installation_source";

    # select appropriate protocol on the network
    assert_and_click "anaconda_install_source_on_the_network";
    send_key "tab";
    wait_still_screen 2;
    # select appropriate repo type for the URL by pressing 'up' a given
    # number of times. default - 3 - is https
    my $num = 3;
    if (get_var("REPOSITORY_GRAPHICAL") =~ m/^nfs:/) {
        $num = 1;
    }
    if (get_var("REPOSITORY_GRAPHICAL") =~ m/^http:/) {
        $num = 4;
    }
    for (my $i=0; $i<$num; $i++) {
        send_key "up";
        usleep 100;
    }
    # we accept any of the protocol needles here, if we happened to
    # choose wrong the test will fail soon anyhow
    assert_screen "anaconda_install_source_selected";

    # insert the url
    wait_screen_change { send_key "tab"; };
    my $repourl = "";

    # if either MIRRORLIST_GRAPHICAL or REPOSITORY_GRAPHICAL is set, type this into
    # the repository url input
    if (get_var("MIRRORLIST_GRAPHICAL")) {
        $repourl = get_mirrorlist_url();
        type_safely $repourl;

        # select as mirror list
        my $relnum = get_release_number;
        send_key "tab";
        send_key "tab";
        send_key "down";
    }
    elsif (get_var("REPOSITORY_GRAPHICAL")) {
        $repourl = get_full_repo(get_var("REPOSITORY_GRAPHICAL"));
        # strip the nfs and nfsvers prefix if present for typing here
        $repourl =~ s/^nfs://;
        $repourl =~ s/^nfsvers=.://;
        type_safely $repourl;
    }

    assert_and_click "anaconda_spoke_done";

    wait_still_screen 2;

    # if the internet connection was too slow the mirrorlist shows as error
    # so needs to be applied a second time
    if (check_screen('anaconda_main_hub_installation_source_error', 10)) {
        # Go into the Install Source spoke
        assert_and_click "anaconda_main_hub_installation_source_error";

        # and back again
        assert_and_click "anaconda_spoke_done";
    }

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
