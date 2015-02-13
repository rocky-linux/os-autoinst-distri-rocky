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


        ## Select minimal flavor
        if (get_var("FLAVOR") eq "server") {
            autotest::loadtest get_var('CASEDIR')."/tests/_select_minimal.pm";
        }


        ## Disk partitioning
        if (get_var('DISK_GUIDED_MULTI')){
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi.pm";
        }
        elsif (get_var('DISK_GUIDED_DELETE_ALL')){
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_all.pm";
        }
        elsif (get_var('DISK_GUIDED_DELETE_PARTIAL')) {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_partial.pm";
        }
        else {
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_empty.pm";
        }

        if (get_var("ENCRYPT_PASSWORD")){
            autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_encrypted.pm";
        }


        # Start installation, set user & root passwords, reboot
        autotest::loadtest get_var('CASEDIR')."/tests/_do_install_and_reboot.pm";
    }

    # Wait for the login screen
    if (get_var("ENCRYPT_PASSWORD")){
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_encrypted_postinstall.pm";
    }
    autotest::loadtest get_var('CASEDIR')."/tests/_wait_for_login_screen.pm";

    if (get_var('DISK_GUIDED_MULTI'))
    {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_multi_postinstall.pm";
    }

    if (get_var('DISK_GUIDED_DELETE_PARTIAL'))
    {
        autotest::loadtest get_var('CASEDIR')."/tests/disk_guided_delete_partial_postinstall.pm";
    }
}



1;

# vim: set sw=4 et:
