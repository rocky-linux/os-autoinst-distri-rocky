# Copyright (C) 2014 SUSE Linux GmbH
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use testapi;
use autotest;
use needle;

# distribution-specific implementations of expected methods
my $distri = testapi::get_var("CASEDIR") . '/lib/fedoradistribution.pm';
require $distri;
testapi::set_distribution(fedoradistribution->new());

# Stolen from openSUSE.
sub unregister_needle_tags($) {
    my $tag = shift;
    my @a   = @{ needle::tags($tag) };
    for my $n (@a) { $n->unregister(); }
}

sub cleanup_needles() {
    if (!get_var('LIVE')) {
        ## Unregister live-only installer needles. The main issue is the
        ## hub: on non-live we want to wait for repository setup to complete,
        ## but if we match that spoke's "ready" icon, it breaks live because
        ## it doesn't have that spoke. So we have a live needle which doesn't
        ## match on that icon, but we unregister it for non-live installs so
        ## they don't match on it too soon.
        unregister_needle_tags("ENV-INSTALLER-live");
    }
}
$needle::cleanuphandler = \&cleanup_needles;

if (get_var('LIVE')) {
    # No package set selection for lives.
    set_var('PACKAGE_SET', "default");
}

# if user set ENTRYPOINT, run required test directly
# (good for tests where it doesn't make sense to use _boot_to_anaconda, _software_selection etc.)
if (get_var("ENTRYPOINT"))
{
    autotest::loadtest get_var('CASEDIR')."/tests/".get_var("ENTRYPOINT").".pm";
}
elsif (get_var("UPGRADE"))
{
    # all upgrade tests consist of: preinstall phase (where packages are upgraded and fedup is
    # installed), run phase (where fedup is run) and postinstall phase (where is checked if
    # fedora was upgraded successfully)
    autotest::loadtest get_var('CASEDIR')."/tests/upgrade_preinstall.pm";
    autotest::loadtest get_var('CASEDIR')."/tests/upgrade_run.pm";
    # UPGRADE can be set to "minimal", "encrypted", "desktop"...
    autotest::loadtest get_var('CASEDIR')."/tests/upgrade_postinstall_".get_var("UPGRADE").".pm";
}
else
{
    # normal installation test consists of several phases, from which some of them are
    # loaded automatically and others are loaded based on what env variables are set

    # generally speaking, install test consists of: boot phase, customization phase, installation
    # and reboot phase, postinstall phase

    # boot phase is loaded automatically every time
    autotest::loadtest get_var('CASEDIR')."/tests/_boot_to_anaconda.pm";

    # with kickstart tests, booting to anaconda is the only thing required (kickstart file handles
    # everything else)
    unless (get_var("KICKSTART"))
    {

        ## Installation source
        if (get_var('MIRRORLIST_GRAPHICAL') || get_var("REPOSITORY_GRAPHICAL")){
            autotest::loadtest get_var('CASEDIR')."/tests/install_source_graphical.pm";
        }
        if (get_var("REPOSITORY_VARIATION")){
            autotest::loadtest get_var('CASEDIR')."/tests/install_source_variation.pm";
        }

        ## Select package set. Minimal is the default, if 'default' is specified, skip selection.
        autotest::loadtest get_var('CASEDIR')."/tests/_software_selection.pm";

        ## Disk partitioning.
        # If DISK_CUSTOM or DISK_GUIDED is set, we pick the storage test
        # to run based on the value (usually we run the test with the name
        # that matches the value, except for a couple of commented cases).
        my $storage = '';
        if (get_var('DISK_CUSTOM')) {
            $storage = get_var('CASEDIR')."/tests/disk_custom_".get_var('DISK_CUSTOM').".pm";
        }
        else {
            my $disk_guided = get_var('DISK_GUIDED');
            # if DISK_GUIDED is unset, or one of [...], use disk_guided_empty,
            # which is the simplest / 'default' case.
            if (! $disk_guided || $disk_guided ~~ ['empty', 'free_space']) {
                $storage = get_var('CASEDIR')."/tests/disk_guided_empty.pm";
            }
            else {
                $storage = get_var('CASEDIR')."/tests/disk_guided_".$disk_guided.".pm";
            }
        }
        autotest::loadtest $storage;

        if (get_var("ENCRYPT_PASSWORD")){
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_encrypted.pm";
        }

        # Start installation, set user & root passwords, reboot
        # install and reboot phase is loaded automatically every time (except when KICKSTART is set)
        autotest::loadtest get_var('CASEDIR')."/tests/_do_install_and_reboot.pm";
    }

    # Unlock encrypted storage volumes, if necessary. The test name here
    # follows the 'storage post-install' convention, but must be run earlier.
    if (get_var("ENCRYPT_PASSWORD")){
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_encrypted_postinstall.pm";
    }

    # Appropriate login method for install type
    if (get_var("DESKTOP")) {
        autotest::loadtest get_var('CASEDIR')."/tests/_graphical_wait_login.pm";
    }
    else {
        autotest::loadtest get_var('CASEDIR')."/tests/_console_wait_login.pm";
    }

    # from now on, we have fully installed and booted system with root/specified user logged in

    # If there is a post-install test to verify storage configuration worked
    # correctly, run it. Again we determine the test name based on the value
    # of DISK_CUSTOM or DISK_GUIDED.
    my $storagepost = '';
    if (get_var('DISK_GUIDED')) {
        my $loc = get_var('CASEDIR')."/tests/disk_guided_".get_var('DISK_GUIDED')."_postinstall.pm";
        $storagepost = $loc if (-e $loc);
    }
    elsif (get_var('DISK_CUSTOM')) {
        my $loc = get_var('CASEDIR')."/tests/disk_custom_".get_var('DISK_CUSTOM')."_postinstall.pm";
        $storagepost = $loc if (-e $loc);
    }
    autotest::loadtest $storagepost if ($storagepost);
}



1;

# vim: set sw=4 et:
