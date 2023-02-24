use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->root_console(tty => 4);
    # Point at default repositories by modifying contentdir
    # NOTE: This will leave repos pointing at primary dl server instead
    #       of mirrorlist.
    script_run 'printf "pub/rocky\n" > /etc/dnf/vars/contentdir';
    script_run 'dnf clean all';
    script_run 'dnf repoinfo';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
