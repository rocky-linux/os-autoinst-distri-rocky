use base "installedtest";
use strict;
use testapi;
use utils;

sub _soft_fail_run {
    my ($test, $sudo) = @_;
    $sudo //= 1;
    my $cmd = "";
    $cmd = "sudo " if ($sudo);
    $cmd .= "python3 -m unittest";
    if (script_run "$cmd $test -v") {
        record_soft_failure "Non-blocking test $test failed";
    }
}

sub run {
    # This test is basically a recreation of exactly the test process
    # autocloud used to use, via tunir and this tunir config:
    # https://infrastructure.fedoraproject.org/cgit/ansible.git/tree/roles/autocloud/backend/files/fedora.txt?id=6e7c1b90593df8371fd34ed9484bd4da119236d3
    my $self = shift;
    # we need to use script_run as regular user
    assert_script_run "chmod ugo+w /dev/" . $serialdev;
    # let's go to another tty and login as regular user
    send_key "alt-f2";
    console_login(user => "test", password => "weakpassword");
    assert_script_run "curl -O https://fedorapeople.org/groups/qa/tunirtests.tar.gz";
    assert_script_run "tar xvf tunirtests.tar.gz";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestAtomic01Status -v";
    _soft_fail_run "tunirtests.nongatingtests.TunirNonGatingtests";
    _soft_fail_run "tunirtests.nongatingtests.TunirNonGatingtestBzip2";
    _soft_fail_run "tunirtests.nongatingtests.TunirNonGatingtestsCpio";
    _soft_fail_run "tunirtests.nongatingtests.TunirNonGatingtestDiffutills";
    _soft_fail_run "tunirtests.nongatingtests.TunirNonGatingtestaudit";
    _soft_fail_run "tunirtests.selinux.TestSELinux";
    _soft_fail_run "tunirtests.sshkeygentest.sshkeygenTest";
    _soft_fail_run "tunirtests.testumountroot.TestUmountRoot";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudtests.TestBase -v";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudtests.TestCloudtmp -v";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudtests.Testtmpmount -v";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudtests.Testnetname -v";
    # this test only works properly as a regular user
    _soft_fail_run "tunirtests.cloudtests.TestJournalWritten", 0;
    assert_script_run "sudo python3 -m unittest tunirtests.cloudservice.TestServiceStop -v";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudservice.TestServiceDisable -v";
    type_string "sudo reboot\n";
    boot_to_login_screen(timeout => 180);
    console_login(user => "root", password => "weakpassword");
    # we need to use script_run as regular user again
    assert_script_run "sudo chmod ugo+w /dev/" . $serialdev;
    # let's go to another tty and login as regular user again
    send_key "alt-f2";
    console_login(user => "test", password => "weakpassword");
    _soft_fail_run "tunirtests.testreboot.TestReboot";
    assert_script_run "sudo python3 -m unittest tunirtests.cloudservice.TestServiceManipulation -v";
    # this test only works properly as a regular user
    _soft_fail_run "tunirtests.cloudtests.TestJournalWrittenAfterReboot", 0;
    type_string "sudo reboot\n";
    boot_to_login_screen(timeout => 180);
    console_login(user => "root", password => "weakpassword");
    # we need to use script_run as regular user again
    assert_script_run "sudo chmod ugo+w /dev/" . $serialdev;
    # let's go to another tty and login as regular user again
    send_key "alt-f2";
    console_login(user => "test", password => "weakpassword");
    assert_script_run "sudo python3 -m unittest tunirtests.cloudservice.TestServiceAfter -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestDockerInstalled -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestDockerStorageSetup -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestAtomicFirstBootRun -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestAtomicCommand -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestAtomicDockerImage -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestRootMount -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.Testreadonlymount -v";
    assert_script_run "sudo python3 -m unittest tunirtests.atomictests.TestDockerDaemon -v";
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
