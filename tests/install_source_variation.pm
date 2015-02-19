use base "anacondalog";
use strict;
use testapi;

sub run {
    # !!! GRUB parameter is set in _boot_to_anaconda.pm !!!

    # Anaconda hub
    assert_screen "anaconda_main_hub";

    # FIXME: this code is scattered in at least three places (here, _boot_to_anaconda, _install_source_graphical. Deduplicate
    my $fedora_version = lc((split /_/, get_var("BUILD"))[0]);
    my $repourl = "";

    $repourl = "download.fedoraproject.org/pub/fedora/linux/development/".$fedora_version."/".get_var("ARCH")."/os";

    # check that the repo was used
    send_key "ctrl-alt-f2";
    wait_idle 10;
    type_string "grep \"".$repourl."\" /tmp/packaging.log"; #| grep \"added repo\"";
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
