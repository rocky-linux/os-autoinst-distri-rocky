package main_common;

use strict;

use base 'Exporter';
use Exporter;

use testapi;

our @EXPORT = qw/run_with_error_check/;

sub run_with_error_check {
    my ($func, $error_screen) = @_;
    die "Error screen appeared" if (check_screen $error_screen, 5);
    $func->();
    die "Error screen appeared" if (check_screen $error_screen, 5);
}
