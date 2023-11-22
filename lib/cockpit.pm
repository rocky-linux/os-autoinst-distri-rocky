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
    # on localhost) shown. If login is truth-y, also log in. If login
    # and admin are both truthy, also gain admin privileges. Assumes
    # X and Firefox are installed.
    my %args = @_;
    $args{login} //= 0;
    $args{admin} //= 1;
    my $login = shift || 0;
    # https://bugzilla.redhat.com/show_bug.cgi?id=1439429
    assert_script_run "sed -i -e 's,enable_xauth=1,enable_xauth=0,g' /usr/bin/startx";
    disable_firefox_studies;
    # run firefox directly in X as root. never do this, kids!
    type_string "startx /usr/bin/firefox -width 1024 -height 768 http://localhost:9090\n";
    assert_screen "cockpit_login", 60;
    # this happened on early Modular Server composes...
    record_soft_failure "Unbranded Cockpit" if (match_has_tag "cockpit_login_unbranded");
    wait_still_screen(stilltime => 5, similarity_level => 45);
    if ($args{login}) {
        type_safely "test";
        wait_screen_change { send_key "tab"; };
        type_safely get_var("USER_PASSWORD", "weakpassword");
        send_key "ret";
        if ($args{admin}) {
            assert_and_click "cockpit_admin_enable";
            assert_screen "cockpit_admin_password";
            type_safely get_var("USER_PASSWORD", "weakpassword");
            send_key "ret";
        }
        assert_screen "cockpit_main";
        # wait for any animation or other weirdness
        # can't use wait_still_screen because of that damn graph
        sleep 3;
    }
}

sub select_cockpit_update {
    # This method navigates to to the updates screen
    # From Firefox 100 on, we get 'adaptive scrollbars', which means
    # the scrollbar is just invisible unless you moved the mouse
    # recently. So we click in the search box and hit 'down' to scroll
    # the sidebar as often as needed to show the button
    assert_screen ["cockpit_software_updates", "cockpit_search"], 120;
    click_lastmatch;
    if (match_has_tag "cockpit_search") {
        send_key_until_needlematch("cockpit_software_updates", "down", 10);
        assert_and_click "cockpit_software_updates";
    }
    # wait for the updates to download
    assert_screen 'cockpit_updates_check', 300;
}

sub check_updates {
    my $logfile = shift;
    sleep 2;
    my $checkresult = script_run "dnf check-update > $logfile";
    upload_logs "$logfile", failok => 1;
    return ($checkresult);
}
