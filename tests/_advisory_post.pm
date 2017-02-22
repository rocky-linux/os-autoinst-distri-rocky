use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # figure out which packages from the update actually got installed
    # (if any) as part of this test
    $self->root_console(tty=>3);
    assert_script_run 'rpm -qa --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" | sort -u > /tmp/allpkgs.txt';
    # this finds lines which appear in both files
    # http://www.unix.com/unix-for-dummies-questions-and-answers/34549-find-matching-lines-between-2-files.html
    assert_script_run 'comm -12 /tmp/allpkgs.txt /var/log/updatepkgs.txt > /var/log/testedpkgs.txt';
    upload_logs "/var/log/testedpkgs.txt";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
