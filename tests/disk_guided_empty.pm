use base "anacondatest";
use strict;
use testapi;
use anaconda;
use utils;

sub run {
    my $self = shift;
    # If we want to test graphics during installation, we need to
    # call the test suite with an "IDENTIFICATION=true" variable.
    my $identification = get_var('IDENTIFICATION');
    # Anaconda hub
    # Go to INSTALLATION DESTINATION and ensure one disk is selected.
    select_disks();

    # updates.img tests work by changing the appearance of the INSTALLATION
    # DESTINATION screen, so check that if needed.
    if (get_var('TEST_UPDATES')){
        assert_screen "anaconda_install_destination_updates", 30;
    }
   # Here the self identification test code is placed.
   my $branched = get_var('VERSION');
   if ($identification eq 'true' or $branched ne "Rawhide") {
       check_top_bar(); # See utils.pm
       # disabled because we have issues with false needle matches
       # on the pre-release note when it's dark red text on a dark
       # blue background - os-autoinst greyscales images before
       # comparing, and they wind up the same shade of grey, so we
       # will get a 'match' for the pre-release needle even if the
       # text is not there at all:
       # https://progress.opensuse.org/issues/56822
       # check_prerelease();
       check_version();
   }

    assert_and_click "anaconda_spoke_done";

    # Anaconda hub
    assert_screen "anaconda_main_hub", 300; #

}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
