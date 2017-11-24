use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # check cockpit appears to be enabled and running and firewall is setup
    assert_script_run 'systemctl is-enabled cockpit.socket';
    assert_script_run 'systemctl is-active cockpit.socket';
    assert_script_run 'firewall-cmd --query-service cockpit';
    # use compose repo, disable u-t, etc.
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
    assert_script_run "dnf ${extraparams} -y install firefox", 160;
    start_cockpit(0);
    # quit firefox (return to console)
    send_key "ctrl-q";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
