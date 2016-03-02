use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Go into the Install Source spoke
    assert_and_click "anaconda_main_hub_installation_source";

    # select "http" on the network
    assert_and_click "anaconda_install_source_on_the_network";
    send_key "tab";
    for (my $i=0; $i<4; $i++){
        send_key "up";
    }
    assert_screen "anaconda_install_source_http_selected";


    # insert the url
    send_key "tab";
    my $repourl = "";

    # if either MIRRORLIST_GRAPHICAL or REPOSITORY_GRAPHICAL is set, type this into
    # the repository url input
    if (get_var("MIRRORLIST_GRAPHICAL")){
        $repourl = "mirrors.fedoraproject.org/mirrorlist?repo=fedora-".lc(get_var("VERSION"))."&arch=".get_var('ARCH');
        type_string $repourl;

        # select as mirror list
        assert_and_click "anaconda_install_source_repo_select_mirrorlist";
    }
    elsif (get_var("REPOSITORY_GRAPHICAL")){
        $repourl = get_var("REPOSITORY_GRAPHICAL")."/".lc(get_var("VERSION"))."/".get_var("ARCH")."/os";
        type_string $repourl;
    }

    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;

    # check that the repo was used
    $self->root_console;
    validate_script_output "grep \"".$repourl."\" /tmp/packaging.log", sub { $_ =~ m/added repo: 'anaconda'/ };
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
