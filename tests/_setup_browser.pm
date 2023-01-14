use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    
    # set up appropriate repositories
    repo_setup();
    # use --enablerepo=fedora for Modular compose testing (we need to
    # create and use a non-Modular repo to get some packages which
    # aren't in Modular Server composes)
    my $extraparams = '';
    $extraparams = '--enablerepo=fedora' if (get_var("MODULAR"));
    # install a desktop and firefox so we can actually try it
    assert_script_run "dnf ${extraparams} -y groupinstall 'base-x'", 300;
    # FIXME: this should probably be in base-x...X seems to fail without
    assert_script_run "dnf ${extraparams} -y install libglvnd-egl", 160;
    # try to avoid random weird font selection happening
    assert_script_run "dnf ${extraparams} -y install dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts", 160;
    # since firefox-85.0-2, firefox doesn't seem to run without this
    assert_script_run "dnf ${extraparams} -y install dbus-glib", 160;
    assert_script_run "dnf ${extraparams} -y install firefox", 160;
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
