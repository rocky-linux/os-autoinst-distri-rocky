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
    if (script_run 'comm -12 /tmp/allpkgs.txt /var/log/updatepkgs.txt > /var/log/testedpkgs.txt') {
        # occasionally, for some reason, it's unhappy about sorting;
        # we shouldn't fail the test in this case, just upload the
        # files so we can see why...
        upload_logs "/tmp/allpkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
    }
    # we'll try and upload the output even if comm 'failed', as it
    # does in fact still write it in some cases
    upload_logs "/var/log/testedpkgs.txt", failok=>1;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
