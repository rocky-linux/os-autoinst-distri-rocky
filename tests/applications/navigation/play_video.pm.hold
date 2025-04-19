use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that
# - a video can be played both full screen or normal

sub run {
    my $self = shift;
    # Start the Video player
    menu_launch_type("videos");
    assert_screen("apps_run_videos");
    # The Video player should start with a grid view
    # of videos, check that it runs and that the
    # video is displayed in that view or we will add
    # the video to the grid.
    unless (check_screen("video_grid_shown", 10)) {
        assert_and_click("video_add_video");
        assert_and_click("video_add_local_video");
        wait_still_screen(3);
        assert_and_click("gnome_filedialogue_videos");
        assert_and_click("video_add_button");
    }
    assert_screen("video_grid_shown");
    # We will start the Video by clicking on the icon
    click_lastmatch();
    # The Video should not start in the full screen mode
    # therefore, we check for panel controls.
    assert_screen("panel_controls");
    # We wait for a couple of seconds and then we try
    # to stop the video to make some screen assertion.
    sleep(3);
    # Stop the Video
    send_key("spc");
    # Check that correct picture is shown.
    assert_screen("video_first_stop");
    # Continue, wait three seconds, stop and repeat.
    send_key("spc");
    sleep(3);
    # Stop the video for the second time.
    send_key("spc");
    assert_screen("video_second_stop");
    # Continue and switch to full screen
    send_key("spc");
    sleep(1);
    send_key("f");
    # And stop the video
    send_key("spc");
    # We should be in the full screen
    # mode and no panels should be visible.
    assert_screen("video_fullscreen_on");
    # Start the video again.
    send_key("spc");
    sleep(2);
    send_key("spc");
    assert_screen("video_third_stop");
    # Continue playing, make video not
    # full screen again, check the panels.
    send_key("spc");
    sleep(1);
    send_key("f");
    send_key("spc");
    assert_screen("video_fullscreen_off", timeout => 3);
    # Finish the video and check the content
    send_key("spc");
    assert_screen_change(sub { sleep(1) }, timeout => 2);
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



