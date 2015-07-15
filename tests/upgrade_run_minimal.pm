use base "fedoralog";
use strict;
use testapi;

sub run {
    my $fedup_url;
    my $to_version;
    # FIXME: this is just a workaround, see https://phab.qadevel.cloud.fedoraproject.org/T478
    if (get_var("BUILD") =~ /^(\d+)_Final_(.*)$/) {
        $fedup_url = "https://dl.fedoraproject.org/pub/alt/stage/".$1."_".$2."/Server/".get_var("ARCH")."/os";
        $to_version = $1;
    } else {
        $fedup_url = "https://dl.fedoraproject.org/pub/alt/stage/".get_var("BUILD")."/Server/".get_var("ARCH")."/os";
        get_var("BUILD") =~ /^(\d+)/;
        $to_version = $1;
    }

    type_string "fedup --network ".$to_version." --instrepo ".$fedup_url;
    send_key "ret";

    wait_still_screen 30, 6000; # TODO: shorter timeout, longer stillscreen?

    upload_logs "/var/log/fedup.log";

    type_string "reboot";
    send_key "ret";

    assert_screen "grub_fedup", 30;
    send_key "ret";

    assert_screen "text_console_login", 6000;
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
