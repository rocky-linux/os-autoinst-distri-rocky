package main_common;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
our @EXPORT = qw/run_with_error_check check_type_string type_safely type_very_safely/;

sub run_with_error_check {
    my ($func, $error_screen) = @_;
    die "Error screen appeared" if (check_screen $error_screen, 5);
    $func->();
    die "Error screen appeared" if (check_screen $error_screen, 5);
}

# type the string in sets of characters at a time (default 3), waiting
# for a screen change after each set. Intended to be safer when the VM
# is busy and regular type_string may overload the input buffer. Args
# passed along to `type_string`. Accepts additional args:
# `size` - size of character groups (default 3) - set to 1 for extreme
#          safety (but slower and more screenshotting)
sub check_type_string {
    my ($string, %args) = @_;
    $args{size} //= 3;

    # split string into an array of pieces of specified size
    # https://stackoverflow.com/questions/372370
    my @pieces = unpack("(a$args{size})*", $string);
    for my $piece (@pieces) {
        wait_screen_change { type_string($piece, %args); };
    }
}

# high-level 'type this string quite safely but reasonably fast'
# function whose specific implementation may vary
sub type_safely {
    my $string = shift;
    check_type_string($string, max_interval => 20);
    wait_still_screen 2;
}

# high-level 'type this string extremely safely and rather slow'
# function whose specific implementation may vary
sub type_very_safely {
    my $string = shift;
    check_type_string($string, size => 1, still => 5, max_interval => 1);
    wait_still_screen 5;
}
