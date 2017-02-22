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

## UTILITY SUBROUTINES


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

## TEST LOADING SUBROUTINES


sub load_upgrade_tests() {
    # all upgrade tests consist of: preinstall phase (where packages are upgraded and
    # dnf-plugin-system-upgrade is installed), run phase (where upgrade is run) and postinstall
    # phase (where is checked if fedora was upgraded successfully)
    autotest::loadtest "tests/upgrade_preinstall.pm";
    autotest::loadtest "tests/upgrade_run.pm";
    # set postinstall test
    set_var('POSTINSTALL', "upgrade_postinstall" );
}

sub load_install_tests() {
    # normal installation test consists of several phases, from which some of them are
    # loaded automatically and others are loaded based on what env variables are set

    # generally speaking, install test consists of: boot phase, customization phase, installation
    # and reboot phase, postinstall phase

    # boot phase is loaded automatically every time
    autotest::loadtest "tests/_boot_to_anaconda.pm";

    # if this is a kickstart install, that's all folks
    return if (get_var("KICKSTART"));

    if (get_var('ANACONDA_TEXT')) {
        # since it differs much, handle text installation separately
        autotest::loadtest "tests/install_text.pm";
        return;
    }

    ## Networking
    if (get_var('ANACONDA_STATIC')) {
        autotest::loadtest "tests/_anaconda_network_static.pm";
    }

    ## Installation source
    if (get_var('MIRRORLIST_GRAPHICAL') || get_var("REPOSITORY_GRAPHICAL")) {
        autotest::loadtest "tests/install_source_graphical.pm";
        autotest::loadtest "tests/_check_install_source.pm";
    }
    if (get_var("REPOSITORY_VARIATION")){
        autotest::loadtest "tests/_check_install_source.pm";
    }

    if (get_var('LIVE')) {
        # No package set selection for lives.
        set_var('PACKAGE_SET', "default");
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

sub _load_early_postinstall_tests() {
    # Early post-install test loading. Split out as a separate sub
    # because we do this all twice on update tests.

    # Unlock encrypted storage volumes, if necessary. The test name here
    # follows the 'storage post-install' convention, but must be run earlier.
    if (get_var("ENCRYPT_PASSWORD")) {
        autotest::loadtest "tests/disk_guided_encrypted_postinstall.pm";
    }

    # Appropriate login method for install type
    if (get_var("DESKTOP")) {
        autotest::loadtest "tests/_graphical_wait_login.pm";
    }
    # Test non-US input at this point, on language tests
    if (get_var("SWITCHED_LAYOUT") || get_var("INPUT_METHOD")) {
        autotest::loadtest "tests/_graphical_input.pm";
    }
    unless (get_var("DESKTOP")) {
        autotest::loadtest "tests/_console_wait_login.pm";
    }
}

sub load_postinstall_tests() {
    # special case for the memory check test, as it doesn't need to boot
    # the installed system: just load its test and return
    if (get_var("MEMCHECK")) {
        autotest::loadtest "tests/_memcheck.pm";
        return;
    }

    # load the early tests
    _load_early_postinstall_tests();

    # do standard post-install static network config if the var is set
    # this is here not in early_postinstall_tests as there's no need
    # to do it twice
    if (get_var("POST_STATIC")) {
        autotest::loadtest "tests/_post_network_static.pm";
    }

    # if scheduler passed an advisory, update packages from that advisory
    # (intended for the updates testing workflow, so we install the updates
    # to be tested)
    if (get_var("ADVISORY")) {
        autotest::loadtest "tests/_advisory_update.pm";
        # now load the early boot tests again, as _advisory_update reboots
        _load_early_postinstall_tests();
    }
    # from now on, we have fully installed and booted system with root/specified user logged in

    # If there is a post-install test to verify storage configuration worked
    # correctly, run it. Again we determine the test name based on the value
    # of PARTITIONING
    my $storagepost = '';
    if (get_var('PARTITIONING')) {
        my $casedir = get_var("CASEDIR");
        my $loc = "tests/disk_" . get_var('PARTITIONING') . "_postinstall.pm";
        $storagepost = $loc if (-e "$casedir/$loc");
    }
    autotest::loadtest $storagepost if ($storagepost);

    if (get_var("UEFI")) {
        autotest::loadtest "tests/uefi_postinstall.pm";
    }

    # console avc / crash check
    # it makes no sense to run this after logging in on most post-
    # install tests (hence ! BOOTFROM) but we *do* want to run it on
    # upgrade tests after upgrading (hence UPGRADE)
    # desktops have specific tests for this (hence !DESKTOP). For
    # desktop upgrades we should really upload a disk image at the end
    # of upgrade and run all the desktop post-install tests on that
    if (!get_var("DESKTOP") && (!get_var("BOOTFROM") || get_var("UPGRADE"))) {
        autotest::loadtest "tests/_console_avc_crash.pm";
    }

    # generic post-install test load
    if (get_var("POSTINSTALL")) {
        my @pis = split(/ /, get_var("POSTINSTALL"));
        foreach my $pi (@pis) {
            autotest::loadtest "tests/${pi}.pm";
        }
    }

    # load the ADVISORY post-install test - this records which update
    # packages were actually installed during the test
    if (get_var("ADVISORY")) {
        autotest::loadtest "tests/_advisory_post.pm";
    }

    # we should shut down before uploading disk images
    if (get_var("STORE_HDD_1") || get_var("PUBLISH_HDD_1")) {
        autotest::loadtest "tests/_console_shutdown.pm";
    }
}

## LOADING STARTS HERE


# if user set ENTRYPOINT, run required test directly
# (good for tests where it doesn't make sense to use _boot_to_anaconda, _software_selection etc.)
# if you want to run more than one test via ENTRYPOINT, separate them with space
if (get_var("ENTRYPOINT")) {
    my @entrs = split(/ /, get_var("ENTRYPOINT"));
    foreach my $entr (@entrs) {
        autotest::loadtest "tests/${entr}.pm";
    }
}
elsif (get_var("UPGRADE")) {
    load_upgrade_tests;
}
elsif (!get_var("START_AFTER_TEST") && !get_var("BOOTFROM")) {
    # for now we can assume START_AFTER_TEST and BOOTFROM mean the
    # test picks up after an install, so we skip to post-install
    load_install_tests;
}

if (!get_var("ENTRYPOINT")) {
    load_postinstall_tests;
}

1;

# vim: set sw=4 et:
