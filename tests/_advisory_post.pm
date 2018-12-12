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

    # now, try and figure out if we have a different version of any
    # package from the update installed - this indicates a problem,
    # it likely means a dep issue meant dnf installed an older version
    # from the frozen release repo
    script_run 'touch /tmp/installedupdatepkgs.txt';
    script_run 'for pkg in $(cat /var/log/updatepkgnames.txt); do rpm -q $pkg && rpm -q $pkg --qf "%{SOURCERPM} %{EPOCH} %{NAME}-%{VERSION}-%{RELEASE}\n" >> /tmp/installedupdatepkgs.txt; done';
    script_run 'sort -u -o /tmp/installedupdatepkgs.txt /tmp/installedupdatepkgs.txt';
    # now, /tmp/installedupdatepkgs.txt is a sorted list of installed packages
    # with the same name as packages from the update, in the same form as
    # /var/log/updatepkgs.txt; so if any line appears in installedupdatepkgs.txt
    # but not updatepkgs.txt, we have a problem.
    if (script_run 'comm -23 /tmp/installedupdatepkgs.txt /var/log/updatepkgs.txt > /var/log/installednotupdatedpkgs.txt') {
        # occasionally, for some reason, it's unhappy about sorting;
        # we shouldn't fail the test in this case, just upload the
        # files so we can see why...
        upload_logs "/tmp/installedupdatepkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
    }
    # this exits 1 if the file is zero-length, 0 if it's longer
    # if it's 0, that's *BAD*: we want to upload the file and fail
    unless (script_run 'test -s /var/log/installednotupdatedpkgs.txt') {
        upload_logs "/var/log/installednotupdatedpkgs.txt", failok=>1;
        upload_logs "/var/log/updatepkgs.txt", failok=>1;
        die "Package(s) from update not installed when it should have been! See installednotupdatedpkgs.txt";
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
