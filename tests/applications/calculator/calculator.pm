use base "installedtest";
use strict;
use testapi;
use utils;

# This script checks that Gnome Calculator works in Basic mode.

# This subroutine rewrites the number into a word.
sub rewrite {
    my $number = shift;
    my %numbers = (
        0 => 'zero',
        1 => 'one',
        2 => 'two',
        3 => 'three',
        4 => 'four',
        5 => 'five',
        6 => 'six',
        7 => 'seven',
        8 => 'eight',
        9 => 'nine',
        "." => 'divider',
        "%" => 'percent',
        "p" => 'pi',
        "r" => 'root',
        "s" => 'square'
    );
    my $rewritten = $numbers{$number};
    return $rewritten;
}

# This subroutine performs the clicking of simple operations
# in the Calculator.
sub calculate {
    my ($a, $b, $operation) = @_;
    # Create lists of the numbers.
    my @first = split('', $a);
    my @second = split('', $b);

    # For each digit of the first number, click on
    # the corresponding button.
    foreach (@first) {
        my $word = rewrite($_);
        assert_and_click("calc_button_$word");
    }
    # Click the operation button.
    assert_and_click("calc_button_$operation");
    # For each digit of the second number, click on
    # the corresponding button.
    foreach (@second) {
        my $word = rewrite($_);
        assert_and_click("calc_button_$word");
    }
    # Click on the Equals button
    assert_and_click("calc_button_equals");
    # Assert the result has appeared on the screen.
    my $identifier = hashed_string("$a-$operation-$b");
    assert_screen("calc_result_$identifier");
    # Clear the display.
    send_key("esc");
}

sub run {
    my $self = shift;
    # Wait until everything settles.
    sleep 5;
    # Check that two numbers can be added.
    calculate("10", "23", "add");
    # Check that two numbers can be subtracted.
    calculate("67", "45", "sub");
    # Check that two numbers can be multiplied.
    calculate("9", "0.8", "multi");
    # Check that two numbers can be divided.
    calculate("77", "7", "div");
    # Check that two numbers can be divided using modulo.
    calculate("28", "5", "mod");
    # Check that you can count with Pi
    calculate("p", "10", "multi");
    # Check that you can use a root
    calculate("r144", "10", "add");
    # Check that you can use square
    calculate("12s", "44", "sub");
    # Check that you can use percents
    calculate("33%", "90", "multi");

    # Check that you can use brackets
    assert_and_click("calc_button_three");
    assert_and_click("calc_button_multi");
    assert_and_click("calc_button_bopen");
    assert_and_click("calc_button_two");
    assert_and_click("calc_button_add");
    assert_and_click("calc_button_three");
    assert_and_click("calc_button_bclose");
    assert_and_click("calc_button_equals");
    my $identifier = hashed_string("3*(3+2)");
    assert_screen("calc_result_$identifier");
    send_key("esc");

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:

