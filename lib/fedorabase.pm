package fedorabase;
use base 'basetest';
use lockapi;

# base class for all Fedora tests

# use this class when using other base class doesn't make sense

use testapi;

sub do_bootloader {
    # Handle bootloader screen. 'bootloader' is syslinux or grub.
    # 'uefi' is whether this is a UEFI install, will get_var UEFI if
    # not explicitly set. 'postinstall' is whether we're on an
    # installed system or at the installer (this matters for how many
    # times we press 'down' to find the kernel line when typing args).
    # 'args' is a string of extra kernel args, if desired. 'mutex' is
    # a parallel test mutex lock to wait for before proceeding, if
    # desired. 'first' is whether to hit 'up' a couple of times to
    # make sure we boot the first menu entry. 'timeout' is how long to
    # wait for the bootloader screen.
    my $self = shift;
    my %args = (
        postinstall => 0,
        params => "",
        mutex => "",
        first => 1,
        timeout => 30,
        uefi => get_var("UEFI"),
        @_
    );
    # if not postinstall and not UEFI, syslinux
    $args{bootloader} //= ($args{uefi} || $args{postinstall}) ? "grub" : "syslinux";
    if ($args{uefi}) {
        # we use the firmware-type specific tags because we want to be
        # sure we actually did a UEFI boot
        assert_screen "bootloader_uefi", $args{timeout};
    } else {
        assert_screen "bootloader_bios", $args{timeout};
    }
    if ($args{mutex}) {
        # cancel countdown
        send_key "left";
        mutex_lock $args{mutex};
        mutex_unlock $args{mutex};
    }
    if ($args{first}) {
        # press up a couple of times to make sure we're at first entry
        send_key "up";
        send_key "up";
    }
    if ($args{params}) {
        if ($args{bootloader} eq "syslinux") {
            send_key "tab";
        }
        else {
            send_key "e";
            # ternary: 13 'downs' to reach the kernel line for installed
            # system, 2 for UEFI installer
            my $presses = $args{postinstall} ? 13 : 2;
            foreach my $i (1..$presses) {
                send_key "down";
            }
            send_key "end";
        }
        type_string " $args{params}";
    }
    # ctrl-X boots from grub editor mode
    send_key "ctrl-x";
    # return boots all other cases
    send_key "ret";
}

sub get_milestone {
    my $self = shift;
    # FIXME: we don't know how to do this with Pungi 4 yet.
    return '';
}

sub clone_host_file {
    # copy a given file from the host into the guest. Mainly used
    # for networking config on tap tests. this is pretty crazy, but
    # SUSE do almost the same thing...
    my $self = shift;
    my $file = shift;
    my $text = '';
    open(my $fh, '<', $file);
    while (<$fh>) {
        $text .= $_;
    }
    assert_script_run "printf '$text' > $file";
    # for debugging...
    assert_script_run "cat $file";
}

sub setup_tap_static {
    # this is a common thing for tap tests, where we set up networking
    # for the system with a static IP address and possibly a specific
    # hostname
    my $self = shift;
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
    # bring up network. DEFROUTE is *vital* here
    assert_script_run "printf 'DEVICE=eth0\nBOOTPROTO=none\nIPADDR=$ip\nGATEWAY=10.0.2.2\nPREFIX=24\nDEFROUTE=yes' > /etc/sysconfig/network-scripts/ifcfg-eth0";
    script_run "systemctl restart NetworkManager.service";
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

sub boot_decrypt {
    # decrypt storage during boot; arg is timeout (in seconds)
    my $self = shift;
    my $timeout = shift || 60;
    assert_screen "boot_enter_passphrase", $timeout; #
    type_string get_var("ENCRYPT_PASSWORD");
    send_key "ret";
}

1;

# vim: set sw=4 et:
