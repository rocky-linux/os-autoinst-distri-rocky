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

# The purpose of this function is to un-register all needles which have
# at least one tag that starts with a given string (the 'prefix'), if
# it does not have any tag that matches the pattern 'prefix-value', for
# any of the values given in an array. The first argument passed must
# be the prefix; the second must be a reference to the array of values.
# For instance, if the 'prefix' is LANGUAGE and the 'values' are
# ENGLISH and FRENCH, this function would un-reference a needle which
# had only the tag 'LANGUAGE-DUTCH', but it would keep a needle which
# had the tag 'LANGUAGE-ENGLISH', or a needle with no tag starting in
# 'LANGUAGE-' at all.
sub unregister_prefix_tags {
    my ($prefix, $valueref) = @_;
    NEEDLE: for my $needle ( needle::all() ) {
        my $unregister = 0;
        for my $tag ( @{$needle->{'tags'}} ) {
            if ($tag =~ /^\Q$prefix/) {
                # We have at least one tag matching the prefix, so we
                # *MAY* want to un-register the needle
                $unregister = 1;
                for my $value ( @{$valueref} ) {
                    # At any point if we hit a prefix-value match, we
                    # know we need to keep this needle and can skip
                    # to the next
                    next NEEDLE if ($tag eq "$prefix-$value");
                }
            }
        }
        # We get here if we hit no prefix-value match, but we only want
        # to unregister the needle if we hit any prefix match, i.e. if
        # 'unregister' is 1.
        $needle->unregister() if ($unregister);
    }
}

sub cleanup_needles() {
    if (!get_var('LIVE') and !get_var('CANNED')) {
        ## Unregister smaller hub needles. Live and 'canned' installers have
        ## a smaller hub with no repository spokes. On other images we want
        ## to wait for repository setup to complete, but if we match that
        ## spoke's "ready" icon, it breaks live and canned because they
        ## don't have that spoke. So we have a needle which doesn't match
        ## on that icon, but we unregister it for other installs so they
        ## don't match on it too soon.
        unregister_needle_tags("INSTALLER-smallhub");
    }

    # Unregister desktop needles of other desktops when DESKTOP is specified
    if (get_var('DESKTOP')) {
        unregister_prefix_tags('DESKTOP', [ get_var('DESKTOP') ])
    }

    # Unregister non-language-appropriate needles. See unregister_except_
    # tags for details; basically all needles with at least one LANGUAGE-
    # tag will be unregistered unless they match the current langauge.
    my $langref = [ get_var('LANGUAGE') || 'english' ];
    unregister_prefix_tags('LANGUAGE', $langref);
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
    autotest::loadtest "tests/".get_var("ENTRYPOINT").".pm";
}
elsif (get_var("UPGRADE"))
{
    # all upgrade tests consist of: preinstall phase (where packages are upgraded and
    # dnf-plugin-system-upgrade is installed), run phase (where upgrade is run) and postinstall
    # phase (where is checked if fedora was upgraded successfully)
    autotest::loadtest "tests/upgrade_preinstall.pm";
    autotest::loadtest "tests/upgrade_run.pm";
    # UPGRADE can be set to "minimal", "encrypted", "desktop"...
    autotest::loadtest "tests/upgrade_postinstall_".get_var("UPGRADE").".pm";
}
else
{
    # normal installation test consists of several phases, from which some of them are
    # loaded automatically and others are loaded based on what env variables are set

    # generally speaking, install test consists of: boot phase, customization phase, installation
    # and reboot phase, postinstall phase

    # boot phase is loaded automatically every time
    autotest::loadtest "tests/_boot_to_anaconda.pm";

    # with kickstart tests, booting to anaconda is the only thing required (kickstart file handles
    # everything else)
    unless (get_var("KICKSTART"))
    {

        ## Installation source
        if (get_var('MIRRORLIST_GRAPHICAL') || get_var("REPOSITORY_GRAPHICAL")){
            autotest::loadtest "tests/install_source_graphical.pm";
        }
        if (get_var("REPOSITORY_VARIATION")){
            autotest::loadtest "tests/install_source_variation.pm";
        }

        ## Select package set. Minimal is the default, if 'default' is specified, skip selection.
        autotest::loadtest "tests/_software_selection.pm";

        ## Disk partitioning.
        # If PARTITIONING is set, we pick the storage test
        # to run based on the value (usually we run the test with the name
        # that matches the value, except for a couple of commented cases).
        my $storage = '';
        my $partitioning = get_var('PARTITIONING');
        # if PARTITIONING is unset, or one of [...], use disk_guided_empty,
        # which is the simplest / 'default' case.
        if (! $partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
            $storage = "tests/disk_guided_empty.pm";
        }
        else {
            $storage = "tests/disk_".$partitioning.".pm";
        }
        autotest::loadtest $storage;

        if (get_var("ENCRYPT_PASSWORD")){
            autotest::loadtest "tests/disk_guided_encrypted.pm";
        }

        # Start installation, set user & root passwords, reboot
        # install and reboot phase is loaded automatically every time (except when KICKSTART is set)
        autotest::loadtest "tests/_do_install_and_reboot.pm";
    }

    # Unlock encrypted storage volumes, if necessary. The test name here
    # follows the 'storage post-install' convention, but must be run earlier.
    if (get_var("ENCRYPT_PASSWORD")){
        autotest::loadtest "tests/disk_guided_encrypted_postinstall.pm";
    }

    # Appropriate login method for install type
    if (get_var("DESKTOP")) {
        autotest::loadtest "tests/_graphical_wait_login.pm";
    }
    else {
        autotest::loadtest "tests/_console_wait_login.pm";
    }

    # from now on, we have fully installed and booted system with root/specified user logged in

    # If there is a post-install test to verify storage configuration worked
    # correctly, run it. Again we determine the test name based on the value
    # of PARTITIONING
    my $storagepost = '';
    if (get_var('PARTITIONING')) {
        my $loc = "tests/disk_".get_var('PARTITIONING')."_postinstall.pm";
        $storagepost = $loc if (-e $loc);
    }
    autotest::loadtest $storagepost if ($storagepost);

    if (get_var("UEFI")) {
        autotest::loadtest "tests/uefi_postinstall.pm";
    }
}



1;

# vim: set sw=4 et:
