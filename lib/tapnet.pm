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
    my $dnstext = '';
    for (my $i=0; $i < @dns; $i++) {
        my $num = $i + 1;
        $dnstext .= "\nDNS" . ${num} . "=" . $dns[$i];
    }
    # bring up network. DEFROUTE is *vital* here
    my $conftext = "DEVICE=eth0\nBOOTPROTO=none\nIPADDR=$ip\nGATEWAY=10.0.2.2\nPREFIX=24\nDEFROUTE=yes\nONBOOT=yes" . $dnstext;
    assert_script_run "printf '${conftext}\n' > /etc/sysconfig/network-scripts/ifcfg-eth0";
    assert_script_run "systemctl restart NetworkManager.service";
    # FIXME workaround for
    # https://bugzilla.redhat.com/show_bug.cgi?id=1727411
    # remove when that's resolved
    script_run 'nmcli con down "Wired connection 1"';
    script_run 'nmcli con down "System eth0"';
    script_run 'nmcli con up "System eth0"';
    # the above doesn't seem to reliably set up resolv.conf, so...
    clone_host_file "/etc/resolv.conf";
}

sub get_host_dns {
    # get DNS server addresses from the host
    my @forwards;
    open(FH, '<', "/etc/resolv.conf");
    while (<FH>) {
        if ($_ =~ m/^nameserver +(.+)/) {
            push @forwards, $1;
        }
    }
    return @forwards;
}

1;

# vim: set sw=4 et:
