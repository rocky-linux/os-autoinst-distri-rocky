use base "installedtest";
use strict;
use testapi;
use utils;

# This test checks that the descriptions in /etc/os-release file are correct and that they
# match the current version.
sub strip_marks {
        # Remove the quotation marks from the string:
        my $string = shift;
        $string=~ tr/"//d;
        return $string;
}

sub run {
        # First, let us define some variables needed to run the program.
        my $self = shift;
        # The file to be checked
        my $filename = '/etc/os-release';

        # Read the content of the file to compare. Let us parse the file
        # and create a hash with those values, so that we can easily access
        # them and assert them.
        my $infile = script_output "cat /etc/os-release";
        my @infile = split /\n/, $infile;
        my %content = ();
        foreach (@infile) {
                chomp $_;
                my ($key, $value) = split /=/, $_;
                $content{$key} = $value;
        }

        # Now, we have all the data ready and we can start testing, first let us get
        # correct variables to compare the system data with.
        # First, we know the basic stuff
        my $id = get_var("DISTRI"); # Should be "fedora"
        # extract expected version components from ISO name for canned variants,
        # which have their os-release rewritten by rpm-ostree, see:
        # https://github.com/projectatomic/rpm-ostree/blob/master/docs/manual/treefile.md
        # we use the ISO name because rpm-ostree uses elements from the compose
        # ID for nightlies, but from the label for candidate composes; BUILD
        # always gives us the compose ID, but the ISO name contains the compose
        # ID for nightlies but the label for candidate composes, so it works for
        # our purposes here.
        my $isovar = get_var("ISO");
        # Split the ISO variable at "-" and read second-to-last (release
        # number) and last (compose ID: date and respin, label: major and
        # minor) fields.
        my ($cannedver, $cannednum) = (split /-/, $isovar)[-2, -1];
        # Get rid of the ".iso" part of the tag.
        $cannednum =~ s/\.iso//g;
        # Now, we merge the fields into one expression to create the correct canned tag
        # that will contain both the version number and the build number.
        my $cannedtag = "$cannedver.$cannednum";
        my $name = ucfirst($id);
        my $rawrel = get_var("RAWREL", '');
        my $version_id = get_var("VERSION"); # Should be the version number or Rawhide.
        # IoT has a branch that acts more or less like Rawhide, but has
        # its version as the Rawhide release number, not 'Rawhide'. This
        # handles that
        $version_id = 'Rawhide' if ($version_id eq $rawrel);
        my $varstr = spell_version_number($version_id);
        my $target = lc($version_id);
        $version_id = $rawrel if ($version_id eq "Rawhide");

        # the 'generic' os-release in fedora-release has no VARIANT or
        # VARIANT_ID and the string used in values like VERSION, that in other
        # cases is the VARIANT, is 'Rawhide' for Rawhide and the spelt version
        # number for other releases. These are the values we'll see for an
        # Everything image.
        my $variant_id = "";
        my $variant = "generic";

        # now replace the values with the correct ones if we are testing a
        # subvariant that maps to a known variant
        my $subvariant = get_var('SUBVARIANT');
        my %variants = (
            Server => ["server", "Server Edition"],
            Workstation => ["workstation", "Workstation Edition"],
            AtomicHost => ["atomic.host", "Atomic Host"],
            CoreOS => ["coreos", "CoreOS"],
            KDE => ["kde", "KDE Plasma"],
            Silverblue => ["silverblue", "Silverblue"],
            IoT => ["iot", "IoT Edition"],
        );
        if (exists($variants{$subvariant})) {
            ($variant_id, $variant) = @{$variants{$subvariant}};
            $varstr = $variant;
        }

        my $version = "$version_id ($varstr)";
        # for canned variants, we need to form a different string here by using
        # the above created cannedtag. See earlier comment
        if (get_var("CANNED")) {
            $version = "$cannedtag ($varstr)";
        }
        my $platform_id = "platform:f$version_id";
        my $pretty = "$name $version_id ($varstr)";
        # Same problem is when testing the PRETTY_NAME.
        if (get_var("CANNED")) {
            $pretty = "$name $cannedtag ($varstr)";
        }

        #Now. we can start testing the real values from the installed system.
        my @fails = ();
        my $failref =\@fails;

        # Test for name
        rec_log "NAME should be $name and is $content{'NAME'}", $content{'NAME'} eq $name, $failref;

        # Test for version.
        my $strip = strip_marks($content{'VERSION'});
        rec_log "VERSION should be $version and is $strip",  $strip eq $version, $failref;

        # Test for version_id
        rec_log "VERSION_ID should be $version_id and is $content{'VERSION_ID'}", $content{'VERSION_ID'} eq $version_id, $failref;

        # Test for platform_id
        $strip = strip_marks($content{'PLATFORM_ID'});
        rec_log "PLATFORM_ID should be $platform_id and is $strip", $strip eq $platform_id, $failref;

        # Test for pretty name
        $strip = strip_marks($content{'PRETTY_NAME'});
        rec_log "PRETTY_NAME should be $pretty and is $strip", $strip eq $pretty, $failref;

        # Test for RH Bugzilla Product
        $strip = strip_marks($content{'REDHAT_BUGZILLA_PRODUCT'});
        rec_log "REDHAT_BUGZILLA_PRODUCT should be $name and is $strip", $strip eq $name, $failref;

        # Test for RH Bugzilla Product Version
        rec_log "REDHAT_BUGZILLA_PRODUCT_VERSION should be $target and is $content{'REDHAT_BUGZILLA_PRODUCT_VERSION'}", $content{'REDHAT_BUGZILLA_PRODUCT_VERSION'} eq $target, $failref;

        # Test for RH Support Product
        $strip = strip_marks($content{'REDHAT_SUPPORT_PRODUCT'});
        rec_log "REDHAT_SUPPORT_PRODUCT should be $name and is $strip", $strip eq $name, $failref;

        # Test for RH Support Product Version
        rec_log "REDHAT_SUPPORT_PRODUCT_VERSION should be $target and is $content{'REDHAT_SUPPORT_PRODUCT_VERSION'}", $content{'REDHAT_SUPPORT_PRODUCT_VERSION'} eq $target, $failref;

        # Test for Variant but only in case of Server or Workstation
        if ($variant ne "generic") {
                $strip = strip_marks($content{'VARIANT'});
                rec_log "VARIANT should be $variant and is $strip", $strip eq $variant, $failref;

                # Test for VARIANT_ID
                rec_log "VARIANT_ID should be $variant_id and is $content{'VARIANT_ID'}", $content{'VARIANT_ID'} eq $variant_id, $failref;
        }
        else {
                print "VARIANT was not tested because the compose is not Workstation or Server Edition.\n";
                print "VARIANT_ID was not tested because the compose is not Workstation or Server Edition.\n";
        }

        # Check for fails, count them, collect their messages and die if something was found.
        my $failcount = scalar @fails;
        script_run "echo \"There were $failcount failures in total.\" >> /tmp/os-release.log";
        upload_logs "/tmp/os-release.log", failok=>1;

        my $failmessages = "";
        foreach my $fail (@fails) {
            $failmessages .= "\n".$fail;
        }
        die $failmessages if ($failcount > 0);
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
