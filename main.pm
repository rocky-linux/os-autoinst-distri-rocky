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

# Boot to anaconda Hub in English

if (get_var("ENTRYPOINT"))
{
    autotest::loadtest get_var('CASEDIR')."/tests/".get_var("ENTRYPOINT").".pm";
}
else
{
    autotest::loadtest get_var('CASEDIR')."/tests/_boot_to_anaconda.pm";

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
        my $packageset = get_var('PACKAGE_SET', 'minimal');
        unless ($packageset eq 'default') {
            autotest::loadtest get_var('CASEDIR')."/tests/_select_".$packageset.".pm";
        }

        ## Disk partitioning
        if (get_var('DISK_GUIDED_MULTI')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi.pm";
        }
        elsif (get_var('DISK_GUIDED_DELETE_ALL')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_all.pm";
        }
        elsif (get_var('DISK_GUIDED_DELETE_PARTIAL')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_partial.pm";
        }
        elsif (get_var('DISK_GUIDED_MULTI_EMPTY_ALL')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi_empty_all.pm";
        }
        elsif (get_var('DISK_SOFTWARE_RAID')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_part_software_raid.pm";
        }
        else {
            # also DISK_GUIDED_FREE_SPACE
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_empty.pm";
        }

        if (get_var("ENCRYPT_PASSWORD")){
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_encrypted.pm";
        }


        # Start installation, set user & root passwords, reboot
        autotest::loadtest get_var('CASEDIR')."/tests/_do_install_and_reboot.pm";
    }

    # Unlock encrypted storage volumes, if necessary
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

    if (get_var('DISK_GUIDED_MULTI')) {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi_postinstall.pm";
    }
    elsif (get_var('DISK_GUIDED_DELETE_PARTIAL')) {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_partial_postinstall.pm";
    }
    elsif (get_var('DISK_GUIDED_FREE_SPACE')) {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_free_space_postinstall.pm";
    }
    elsif (get_var('DISK_GUIDED_MULTI_EMPTY_ALL')) {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi_empty_all_postinstall.pm";
    }
    elsif (get_var('DISK_SOFTWARE_RAID')) {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_part_software_raid_postinstall.pm";
    }
}



1;

# vim: set sw=4 et:
