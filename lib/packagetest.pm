package packagetest;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
our @EXPORT = qw/prepare_test_packages verify_installed_packages verify_updated_packages/;

# enable the openqa test package repositories and install the main
# test packages, remove acpica-tools and install the fake one
sub prepare_test_packages {
    # remove acpica-tools if installed (we don't use assert
    # here in case it's not)
    script_run 'dnf -y remove acpica-tools', 180;
    # grab the test repo definitions
    assert_script_run 'curl -o /etc/yum.repos.d/openqa-testrepo-1.repo https://git.resf.org/testing/openqa-testrepos/raw/branch/main/openqa-testrepo-1.repo';
    # install the test packages from repo1
    assert_script_run 'dnf -y --disablerepo=* --enablerepo=openqa-testrepo-1 install acpica-tools';
    if (get_var("DESKTOP") eq 'kde' && get_var("TEST") eq 'desktop_update_graphical') {
        # kick pkcon so our special update will definitely get installed
        assert_script_run 'pkcon refresh force';
    }
}

# check our test packages installed correctly (this is a test that dnf
# actually does what it claims)
sub verify_installed_packages {
    validate_script_output 'rpm -q acpica-tools', sub { $_ =~ m/^acpica-tools-1-1.noarch$/ };
    assert_script_run 'rpm -V acpica-tools';
}

# check updating the test packages and the fake acpica-tools work
# as expected
sub verify_updated_packages {
    # we don't know what version of acpica-tools we'll actually
    # get, so just check it's *not* the fake one
    validate_script_output 'rpm -q acpica-tools', sub { $_ !~ m/^acpica-tools-1-1.noarch$/ };
    assert_script_run 'rpm -V acpica-tools';
}
