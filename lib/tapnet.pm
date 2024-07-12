package tapnet;

use strict;

use base 'Exporter';
use Exporter;

use testapi;
our @EXPORT = qw/clone_host_file setup_tap_static get_host_dns/;

sub clone_host_file {
    # copy a given file from the host into the guest. Mainly used
    # for networking config on tap tests. this is pretty crazy, but
    # SUSE do almost the same thing...
    my $file = shift;
    my $text = '';
    open(my $fh, '<', $file);
    while (<$fh>) {
        $text .= $_;
    }
    # escape any " characters in the text...
    $text =~ s/"/\\"/g;
    assert_script_run "printf \"$text\" > $file";
    # for debugging...
    assert_script_run "cat $file";
}

sub setup_tap_static {
    # this is a common thing for tap tests, where we set up networking
    # for the system with a static IP address and possibly a specific
    # hostname
    my $ip = shift;
    my $hostname = shift || "";
    if ($hostname) {
        # assigning output of split to a single-item array gives us just
        # the first split
        my ($short) = split(/\./, $hostname);
        # set hostname
        assert_script_run "hostnamectl set-hostname $hostname";
        # add entry to /etc/hosts
        assert_script_run "echo '$ip $hostname $short' >> /etc/hosts";
    }
    # use host's name servers (this is usually going to be correct,
    # tests which don't want this can overwrite resolv.conf)
    my @dns = get_host_dns();
    my $dnstext = 'ipv4.dns "' . join(", ", @dns) . '"';
    # bring up network
    # this gets us the name of the first connection in the list,
    # which should be what we want
    my $connection = script_output "nmcli --fields NAME con show | head -2 | tail -1";
    assert_script_run "nmcli con mod '$connection' ipv4.method manual ipv4.addr $ip/24 ipv4.gateway 172.16.2.2 $dnstext";
    assert_script_run "nmcli con down '$connection'";
    assert_script_run "nmcli con up '$connection'";
    # for debugging
    assert_script_run "nmcli -t con show '$connection'";
}

sub get_host_dns {
    # get DNS server addresses from the host. Assumes host uses
    # systemd-resolved and doesn't use IPv6, for now
    my $result = `/usr/bin/resolvectl status | grep Servers | tail -1 | cut -d: -f2-`;
    # FIXME this is gonna break when we have IPv6 DNS servers on the
    # worker hosts
    my @forwards = split(' ', $result);
    return @forwards;
}

1;

# vim: set sw=4 et:
