use base "installedtest";
use strict;
use testapi;
use utils;

sub slurm_setup {
    # install HPC repository
    my $version = get_var("SLURM_VERSION");
    assert_script_run "dnf -y install rocky-release-hpc", 120;

    # Set up munge
    assert_script_run 'dnf -y install munge --releasever=' . get_version_major, 120;
    assert_script_run "dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key";
    assert_script_run "chmod 400 /etc/munge/munge.key";
    assert_script_run "chown munge.munge /etc/munge/munge.key";
    assert_script_run "systemctl enable --now munge.service";

    # install slurm
    if (get_version_major() eq '8') {
        assert_script_run "dnf config-manager --set-enabled powertools";
    }
    assert_script_run "dnf install -y slurm$version-slurmdbd slurm$version-slurmrestd slurm$version-slurmctld slurm$version-slurmd  --releasever=" . get_version_major;

    # Since this is a single node system, we don't have to modify the conf files. We will for larger multi-node tests.
    # start services
    assert_script_run "systemctl enable --now slurmctld slurmdbd slurmrestd slurmd";
}

sub run {
    my $self = shift;

    # do all the install stuff
    slurm_setup();

    # if everything is configured right, sinfo should show the following output
    # $ sinfo
    #   PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    #   debug*       up   infinite      1   idle localhost
    validate_script_output "sinfo", sub { m/debug.*localhost/ };

    # write a boring job script
    assert_script_run "echo '#!/bin/bash\n#SBATCH --job-name=antarctica_time\nsleep 120\nTZ=NZST date' > job.sh";

    ## schedule a job and run it to completion
    assert_script_run "sbatch job.sh";
    validate_script_output "squeue", sub { m/antar/ };
    sleep 121;
    # after 121 seconds, job should have completed and no longer exist in the queue
    validate_script_output "squeue", sub { $_ !~ m/antar/ };

    ## cancel a job
    assert_script_run "sbatch job.sh";
    validate_script_output "squeue", sub { m/antar/ };
    assert_script_run "scancel 2";
    # job should no longer be in the queue
    validate_script_output "squeue", sub { $_ !~ m/antar/ };
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
