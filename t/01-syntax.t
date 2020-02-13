#!/bin/perl

use FindBin;
unshift @INC, "/usr/libexec/os-autoinst", "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Strict;
all_perl_files_ok(qw 'main.pm lib tests');
