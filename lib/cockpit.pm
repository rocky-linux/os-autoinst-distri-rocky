package cockpit;

use strict;

use base 'Exporter';
use Exporter;
use lockapi;
use testapi;
use utils;

our @EXPORT = qw(start_cockpit select_cockpit_update check_updates);


sub start_cockpit {
    # Starting from a console, get to a browser with Cockpit (running
    # on localhost) shown. If $login is truth-y, also log in. Assumes
    # X and Firefox are installed.
    my $login = shift || 0;
    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    disable_firefox_studies;
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://localhost:9090\n";
    assert_screen "cockpit_login", 30;
    # this happened on early Modular Server composes...
    record_soft_failure "Unbranded Cockpit" if (match_has_tag "cockpit_login_unbranded");
    wait_still_screen 5;
    if ($login) {
        type_safely "root";
        wait_screen_change { send_key "tab"; };
        type_safely get_var("ROOT_PASSWORD", "weakpassword");
        send_key "ret";
        assert_screen "cockpit_main";
        # wait for any animation or other weirdness
        # can't use wait_still_screen because of that damn graph
        sleep 3;
    }
}

sub select_cockpit_update {
    # This method navigates to to the updates screen
    assert_and_click "cockpit_software_updates", '', 120;
    # wait for the updates to download
    assert_screen 'cockpit_updates_check', 300;
}

sub check_updates {
    my $logfile = shift;
    sleep 2;
    my $checkresult = script_run "dnf check-update > $logfile";
    upload_logs "$logfile", failok=>1;
    return($checkresult);
}
