use base "basetest";
use strict;
use testapi;

sub run {
    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

    # Go into the Install Sourcre spoke
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
    my $fedora_version = "";
    my $repourl = "";
    if (get_var("VERSION") eq "rawhide"){
        $fedora_version = "rawhide";
    }
    else {
        $fedora_version = (split /_/, get_var("BUILD"))[0];

        if (get_var("MIRRORLIST_GRAPHICAL")){
            $fedora_version = "fedora-".$fedora_version;
        }
    }

    if (get_var("MIRRORLIST_GRAPHICAL")){
        $repourl = "mirrors.fedoraproject.org/mirrorlist?repo=".$fedora_version."&arch=".get_var('ARCH');
        type_string $repourl;

        # select as mirror list
        assert_and_click "anaconda_install_source_repo_select_mirrorlist";
    }
    elsif (get_var("REPOSITORY_GRAPHICAL")){
        $repourl = "download.fedoraproject.org/pub/fedora/linux/development/".$fedora_version."/".get_var("ARCH")."/os";
        type_string $repourl;
    }

    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300;

    # check that the repo was used
    send_key "ctrl-alt-f3";
    wait_idle 10;
    type_string "grep \"".$repourl."\" /tmp/packaging.log | grep \"added repo\"";
    send_key "ret";
    assert_screen "anaconda_install_source_check_repo_added";
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
