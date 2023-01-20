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
        my $id = get_var("DISTRI"); # Should be "rocky"

        my $name = ucfirst($id);
        # $NAME is "Rocky Linux" not just "Rocky"
        my $fullname = $name . " Linux";

        my $version_id = get_var("VERSION"); # Should be the version number.
        my $ver_major = substr($version_id, 0, index($version_id, q/./));
        my $ver_minor = substr($version_id, index($version_id, q/./), length($version_id));
        my $target = lc($ver_major);
        if ( $ver_major == '9' || '8' ) {
            $target = lc($version_id);
        }

        my $reltag = script_output 'rpm -q rocky-release --qf "%{RELEASE}\n"';
        my $relver = substr($reltag, 0, rindex($reltag, q/./));
        my $eltag = substr($reltag, rindex($reltag, q/./)+1, length($reltag));

        my $code_name = get_code_name();
        my $version = "$version_id ($code_name)";
        my $platform_id = "platform:$eltag";
        my $pretty = "$fullname $version_id ($code_name)";

        #Now. we can start testing the real values from the installed system.
        my @fails = ();
        my $failref =\@fails;

        # Test for name
        my $strip = strip_marks($content{'NAME'});
        rec_log "NAME should be $fullname and is $strip", $strip eq $fullname, $failref;

        # Test for version.
        $strip = strip_marks($content{'VERSION'});
        rec_log "VERSION should be $version and is $strip",  $strip eq $version, $failref;

        # Test for version_id
        $strip = strip_marks($content{'VERSION_ID'});
        rec_log "VERSION_ID should be $version_id and is $strip", $strip eq $version_id, $failref;

        # Test for platform_id
        $strip = strip_marks($content{'PLATFORM_ID'});
        rec_log "PLATFORM_ID should be $platform_id and is $strip", $strip eq $platform_id, $failref;

        # Test for pretty name
        $strip = strip_marks($content{'PRETTY_NAME'});
        rec_log "PRETTY_NAME should be $pretty and is $strip", $strip eq $pretty, $failref;

        # Test for Rocky Support Product
        $strip = strip_marks($content{'ROCKY_SUPPORT_PRODUCT'});
        if ( $ver_major == '9' || '8' ) {
            $fullname = qq/$fullname $ver_major/;
            $fullname =~ s/ /-/g;
        }
        rec_log "ROCKY_SUPPORT_PRODUCT should be $fullname and is $strip", $strip eq $fullname, $failref;

        # Test for Rocky Support Product Version
        $strip = strip_marks($content{ROCKY_SUPPORT_PRODUCT_VERSION});
        rec_log "ROCKY_SUPPORT_PRODUCT_VERSION should be $target and is $strip", $strip eq $target, $failref;

	# VERSION_ID should be 8.4 and is "8.4"
	# PLATFORM_ID should be platform: and is platform:el8
	# ROCKY_SUPPORT_PRODUCT should be Rocky and is Rocky Linux
	# ROCKY_SUPPORT_PRODUCT_VERSION should be  and is 8 at /var/lib/openqa/share/tests/rocky/tests/os_release.pm line 95.

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
