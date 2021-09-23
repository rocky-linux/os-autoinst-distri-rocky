package modularity;

use strict;

use base 'Exporter';
use Exporter;
use lockapi;
use testapi;
use utils;

our @EXPORT = qw(parse_module_list is_listed);

# This subroutine takes the output from the dnf module list command
# and deletes all unnecessary stuff and returns an array of hash 
# references where each hash consists of (module, stream, profile).
# The subroutine only recognizes one profile but it is enough
# for the sake of the modularity testing.

sub parse_module_list {
    my $output = shift;
    my @output_lines = split(/\n/, $output);
    my @parsed_list;

    foreach my $line (@output_lines) {
        my ($module, $stream, $profile) = split(/\s+/, $line);
        unless ($module =~ /Rocky|Last|Hint|Name|^$/) {
            $profile =~ s/,$//;
            my %module = ("module" => $module, "stream" => $stream, "profile" => $profile);
            push(@parsed_list, \%module);
        }
    }
    return @parsed_list;
}

# This subroutine iterates over the given list of module hashes and returns True
# if it finds it in the list.
sub is_listed {
    my ($module, $stream, $listref) = @_;
    my $found = 0;
    foreach (@{ $listref }) {
        if ($_->{module} eq $module and $_->{stream} eq $stream) {
            $found = 1;
        }
    }
    return $found;
}
