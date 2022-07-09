# Copyright (C) 2014 SUSE Linux GmbH
# Copyright Red Hat
#
# This file is part of os-autoinst-distri-fedora.
#
# os-autoinst-distri-fedora is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use testapi;
use autotest;
use needle;
use File::Basename;

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
    # all upgrade tests include: boot phase (where bootloader and
    # encryption are handled if necessary), preinstall phase (where
    # packages are upgraded and dnf-plugin-system-upgrade installed),
    # run phase (where upgrade is run) and postinstall phase (where
    # is checked if fedora was upgraded successfully). The PREUPGRADE
    # variable can be used to specify additional test modules to run
    # after the preinstall phase but before the run phase, and the
    # POSTINSTALL variable can be used to specify additional test
    # modules to run after the upgrade postinstall phase.
    autotest::loadtest "tests/upgrade_boot.pm";
    # if static networking config is needed we must do it at this point
    if (get_var("POST_STATIC")) {
        autotest::loadtest "tests/_post_network_static.pm";
    }
    autotest::loadtest "tests/upgrade_preinstall.pm";
    # generic pre-upgrade test load
    if (get_var("PREUPGRADE")) {
        my @pus = split(/ /, get_var("PREUPGRADE"));
        foreach my $pu (@pus) {
            autotest::loadtest "tests/${pu}.pm";
        }
    }
    autotest::loadtest "tests/upgrade_run.pm";
    # handle additional postinstall tests
    if (get_var("POSTINSTALL")) {
        set_var('POSTINSTALL', "upgrade_postinstall " . get_var("POSTINSTALL"));
    }
    else {
        set_var('POSTINSTALL', "upgrade_postinstall");
    }
}

sub load_install_tests() {
    # CoreOS is special, so we handle that here
    if (get_var("SUBVARIANT") eq "CoreOS") {
        autotest::loadtest "tests/_coreos_install.pm";
        return;
    }
    # normal installation test consists of several phases, from which some of them are
    # loaded automatically and others are loaded based on what env variables are set

    # generally speaking, install test consists of: boot phase, customization phase, installation
    # and reboot phase, postinstall phase

    # boot phase is loaded automatically every time
    autotest::loadtest "tests/_boot_to_anaconda.pm";

    # if this is a kickstart or VNC install, that's all folks
    return if (get_var("KICKSTART") || get_var("VNC_SERVER"));

    # Root password and user creation spokes are suppressed on
    # Workstation live install and Silverblue DVD install, so we do
    # not want to try and use them. Setting this in the templates is
    # tricky as it gets set for post-install tests too that way, and
    # we don't want that
    if ((get_var('LIVE') || get_var('CANNED')) && get_var('DESKTOP') eq 'gnome') {
        set_var('INSTALLER_NO_ROOT', '1');
        # this is effectively a forced install_no_user
        set_var('INSTALL_NO_USER', '1');
    }

    if (get_var('ANACONDA_TEXT')) {
        # since it differs much, handle text installation separately
        autotest::loadtest "tests/install_text.pm";
        return;
    }

    ## Networking
    if (get_var('ANACONDA_STATIC')) {
        autotest::loadtest "tests/_anaconda_network_static.pm";
    }
    else {
        autotest::loadtest "tests/_anaconda_network_enable.pm";
    }

    ## Installation source
    if (get_var('MIRRORLIST_GRAPHICAL') || get_var("REPOSITORY_GRAPHICAL")) {
        autotest::loadtest "tests/install_source_graphical.pm";
        autotest::loadtest "tests/_check_install_source.pm";
    }
    if (get_var("REPOSITORY_VARIATION") || get_var("ADD_REPOSITORY_VARIATION")) {
        autotest::loadtest "tests/_check_install_source.pm";
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

    ## Kdump
    if (get_var('ANACONDA_KDUMP') eq 'enabled') {
        autotest::loadtest "tests/_anaconda_kdump_enable.pm";
    }
    else {
        autotest::loadtest "tests/_anaconda_kdump_disable.pm";
    }

    # Start installation, set user & root passwords, reboot
    # install and reboot phase is loaded automatically every time (except when KICKSTART is set)
    autotest::loadtest "tests/_do_install_and_reboot.pm";
}

sub _load_instance {
    # loads a specific 'instance' of a given test. See next function
    # for more details.
    my ($test, $instance) = @_;
    $test .= "_${instance}" if $instance;
    autotest::loadtest "${test}.pm";
}

sub _load_early_postinstall_tests {
    # Early post-install test loading. Split out as a separate sub
    # because we do this all twice on update tests.

    # openQA isn't very good at handling jobs where the same module
    # is loaded more than once, and fixing that will be a bit complex
    # and no-one got around to it yet. So for now, we use a bit of a
    # hack: for modules we know may get loaded multiple times, we have
    # symlinks named _2, _3 etc. This function can be passed an arg
    # specifying which 'instance' of the tests to use.
    my ($instance) = @_;
    $instance //= 0;

    # Unlock encrypted storage volumes, if necessary. The test name here
    # follows the 'storage post-install' convention, but must be run earlier.
    if (get_var("ENCRYPT_PASSWORD")) {
        _load_instance("tests/disk_guided_encrypted_postinstall", $instance);
    }

    # For now, there's no possibility to get a graphical desktop on
    # Modular composes, so short-circuit here for those
    # Rocky has no such thing as MODULAR composes and we make use of PACKAGESET
    # to select different Environments from the boot and/or DVD ISOs.
    # DO NOT specify DESKTOP for minimal, server-product or virtualization-host
    my $package_set = get_var("PACKAGE_SET");
    if (!get_var("DESKTOP") || get_var("DESKTOP") eq "false" ||
        $package_set eq "minimal" || $package_set eq "server" ||
        $package_set eq "virtualization-host") {
        _load_instance("tests/_console_wait_login", $instance);
        return;
    }

    # Explicitly setting DESKTOP="kde" or DESKTOP="gnome" should ALWAYS trigger
    # graphical login...
    if (get_var("DESKTOP")) {
        _load_instance("tests/_graphical_wait_login", $instance);
    }
    # Test non-US input at this point, on language tests
    if (get_var("SWITCHED_LAYOUT") || get_var("INPUT_METHOD")) {
        _load_instance("tests/_graphical_input", $instance);
    }
    # We do not want to run this on Desktop installations or when
    # the installation is interrupted on purpose.
    unless (get_var("DESKTOP") || get_var("CRASH_REPORT")) {
        _load_instance("tests/_console_wait_login", $instance);
    }
}

sub load_postinstall_tests() {
    # special case for the memory check test, as it doesn't need to boot
    # the installed system: just load its test and return
    if (get_var("MEMCHECK")) {
        autotest::loadtest "tests/_memcheck.pm";
        return;
    }
    # VNC client test's work is done once install is complete
    if (get_var("VNC_CLIENT")) {
        return;
    }

    # load the early tests
    _load_early_postinstall_tests();

    ## enable staging repos if requested
    #if (get_var("DNF_CONTENTDIR")) {
    #    autotest::loadtest "tests/_staging_repos_enable.pm";
    #}

    # do standard post-install static network config if the var is set
    # and this is not an upgrade test (this is done elsewhere in the
    # upgrade workflow)
    # this is here not in early_postinstall_tests as there's no need
    # to do it twice
    if (get_var("POST_STATIC") && !get_var("UPGRADE")) {
        autotest::loadtest "tests/_post_network_static.pm";
    }

    # if scheduler passed an advisory or task ID, update packages from that
    # advisory or task ID (intended for the updates testing workflow, so we
    # install the updates to be tested). Don't do this for UPGRADE tests, as
    # the update gets installed as part of the upgrade in that case and we
    # don't need the extra reboot. Don't do this for INSTALL test(s); these
    # are checking that an installer image built from the update works and do
    # not install the update themselves in this manner
    if (get_var("ADVISORY_OR_TASK") && !get_var("UPGRADE") && !get_var("INSTALL")) {
        autotest::loadtest "tests/_advisory_update.pm";
        # now load the early boot tests again, as _advisory_update reboots
        _load_early_postinstall_tests(2);
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

    if (get_var("UEFI") &! get_var("NO_UEFI_POST") &! get_var("START_AFTER_TEST")) {
        autotest::loadtest "tests/uefi_postinstall.pm";
    }

    # console avc / crash check
    # it makes no sense to run this after logging in on most post-
    # install tests (hence ! BOOTFROM) and we do not want it
    # on crashed installations (hence ! CRASH_REPORT) but we *do* want
    # to run it on upgrade tests after upgrading (hence UPGRADE)
    # desktops have specific tests for this (hence !DESKTOP). For
    # desktop upgrades we should really upload a disk image at the end
    # of upgrade and run all the desktop post-install tests on that
    if (!get_var("DESKTOP") && !get_var("CRASH_REPORT") && (!get_var("BOOTFROM") || get_var("UPGRADE"))) {
        autotest::loadtest "tests/_console_avc_crash.pm";
    }

    # generic post-install test load
    if (get_var("POSTINSTALL")) {
        my @pis = split(/ /, get_var("POSTINSTALL"));
        # For each test in POSTINSTALL, load the test
        foreach my $pi (@pis) {
            autotest::loadtest "tests/${pi}.pm";
        }
    }
    # If POSTINSTALL_PATH is set, we will load all available test files from that location
    # as postinstall tests.
    elsif (get_var("POSTINSTALL_PATH")) {
        my $casedir = get_var("CASEDIR");
        my $path = get_var("POSTINSTALL_PATH");
        # Read the list of files on that path,
        my @pis = glob "${casedir}/${path}/*.pm";
        # and load each of them.
        foreach my $pi (@pis) {
            $pi = basename($pi);
            autotest::loadtest "$path/$pi";
        }
    }

    # load the ADVISORY / KOJITASK post-install test - this records which
    # update or task packages were actually installed during the test. Don't
    # do this for INSTALL test(s); these are checking that an installer image
    # built from the update works and do not install the update themselves.
    if (get_var("ADVISORY_OR_TASK") && !get_var("INSTALL")) {
        # don't do this for support server unless the update is for the same
        # release as the support server disk image, as we don't install the
        # updates on support server when they differ
        unless (get_var("TEST") eq "support_server" && get_var("VERSION") ne get_var("CURRREL")) {
            autotest::loadtest "tests/_advisory_post.pm";
        }
    }

    # we should shut down before uploading disk images
    if (get_var("STORE_HDD_1") || get_var("STORE_HDD_2") || get_var("PUBLISH_HDD_1")) {
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
elsif ((!get_var("START_AFTER_TEST") && !get_var("BOOTFROM") && !get_var("IMAGE_DEPLOY")) || get_var("INSTALL")) {
    # for now we can assume START_AFTER_TEST and BOOTFROM mean the
    # test picks up after an install, and IMAGE_DEPLOY means we're
    # deploying a disk image (no installer) so in those cases we skip
    # to post-install, unless the override INSTALL var is set

    if (get_var("PREINSTALL")) {
        # specified module supposed to first boot to rescue mode
        # do any required actions before to exit rescue mode (triggering reboot).
        # reboot will run through next normal install steps of load_install_tests.
        my @pis = split(/ /, get_var("PREINSTALL"));
        foreach my $pi (@pis) {
            autotest::loadtest "tests/${pi}.pm";
        }
    }

    load_install_tests;
}

if (!get_var("ENTRYPOINT")) {
    load_postinstall_tests;
}

# load application start-stop tests
if (get_var("STARTSTOP")) {
    my $desktop = get_var('DESKTOP');
    my $casedir = get_var('CASEDIR');

    if ($desktop eq 'gnome') {
        # Run this test to preset the environment
        autotest::loadtest "tests/apps_gnome_preset.pm";
    }

    # Find all tests from a directory defined by the DESKTOP variable
    my @apptests = glob "${casedir}/tests/apps_startstop/${desktop}/*.pm";
    # Now load them
    foreach my $filepath (@apptests) {
        my $file = basename($filepath);
        autotest::loadtest "tests/apps_startstop/${desktop}/${file}";
    }
    if ($desktop eq 'gnome') {
        # Run this test to check if required application have registered.
        autotest::loadtest "tests/workstation_core_applications.pm";
    }
}
1;

# vim: set sw=4 et:
