openQA tests for the Fedora distribution
========================================

This repository contains tests and images for testing [Fedora](https://getfedora.org/) with
[openQA](http://os-autoinst.github.io/openQA/). For additional tools, Installation Guide and
Docker images, see [this repository](https://bitbucket.org/rajcze/openqa_fedora_tools).

Test development
----------------
See official documentation [on basic concept](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc),
[test development (including API specification)](https://github.com/os-autoinst/openQA/blob/master/docs/WritingTests.asciidoc),
[needles specification](https://github.com/os-autoinst/os-autoinst/blob/master/doc/needles.txt) and
[supported variables for backend](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backend_vars.asciidoc). See
[this example repo](https://github.com/os-autoinst/os-autoinst-distri-example) on how tests should be structured.

### main.pm modular architecture
Since openQA uses only one entrypoint for all tests (main.pm), we have decided to utilize
this feature and make tests modular. It means that basic passing through main.pm (without any variables set)
results in most basic installation test executed. Developer can customize it with additional variables
(for example by setting `PACKAGE_SET=minimal` to do installation only with minimal package set).

Fedora installation (and consequently main.pm) consists of several parts:

1. booting into Anaconda or booting live image and starting Anaconda

    Since there isn't much variation between tests in this step, we have developed universal `_boot_to_anaconda.pm`
    test that is loaded automatically each time except when `ENTRYPOINT` or `UPGRADE` is set (see VARIABLES.md).

    To customize this step, you can set following variables:

    - `GRUB` is appended to kernel line before boot. You can set for example `inst.updates` here.
    - If `KICKSTART` is set, this part of installation ends here (program doesn't wait for Anaconda to appear).
    Note that you should set `inst.ks` yourself by setting `GRUB` variable.
    - If `LIVE` is set, program waits for desktop to appear and then clicks on "Install to Hard Drive" button.

2. customizing installation by interacting with Anaconda spokes

    Most of the differences between tests take place in this part. If you want to add another installation test,
    you will probably put your variable checking and test loading here. All tests in this part should start on
    Anaconda's main hub and after they done its part, they should go back to Anaconda's main hub so that next
    test could be executed. In this phase, universal `_software_selection.pm` test is loaded that handles
    selecting what software to install.

    To customize this step, you can set following variables:

    - Set `PACKAGE_SET` to install required package set on "Software selection spoke" - you have to provide correct needles with the
    name of `anaconda_${PACKAGE_SET}_highlighted` and `anaconda_${PACKAGE_SET}_selected`.
    - Set `ENCRYPT_PASSWORD` to encrypt disk, value of this variable is used as an actual password.

3. installing Fedora and waiting for Fedora to reboot

    After all customizations are finished, `_do_install_and_reboot.pm` test is automatically loaded.
    It starts installation, creates user and sets root password when required, waits for installation
    to finish and reboots into installed system. Only variables that control flow in this part are these:

    - `ROOT_PASSWORD` to set root password to this value.
    - When set, `USER_LOGIN` and `USER_PASSWORD` are used to create user in Anaconda.

4. post-install phase

    After installation is finished and installed system is fully booted, you can run additional tests
    as checks that installed system has correct attributes - that correct file system is used, that
    RAID is used etc.

Make your test modular, so that it utilizes `_boot_to_anaconda.pm`, `_software_selection.pm` and
`_do_install_and_reboot.pm` tests (that are loaded automatically). Break your test into smaller parts,
each dealing with one specific feature (e. g. partitioning, user creation...) and add their loading
into main.pm based on reasonable variable setting (so they can be used in other tests also).

### Test inheritance
Your test can inherit from `basetest`, `fedorabase`, `installedtest` or `anacondatest`.

- `basetest` is basic class provided by os-autoinst - it has empty `post_fail_hook()` and doesn't set any flags.
- `fedorabase` doesn't neither set flags nor does anything in `post_fail_hook()`, but it provides basic functions
that will be useful during testing Fedora. It should be used when no other, more specific class can be used. It provides
these functions:
    - `console_login()` handles logging in as a root/specified user into console. It requires TTY to
       be already displayed (handled by the `root_console()` method of subclasses). You can configure user and password
       by setting `user` and `password` arguments. If you set `check` argument to 1, this function
       dies if it fails to log in. Example usage: `$self->console_login(user => "garret", password => "weakpassword");`
       logs in as user `garret`, with password `weakpassword`.
    - `boot_to_login_screen()` handles booting from bootloader to login screen. It can take three optional arguments:
       first is the name of the login screen needle that should be displayed when system is booted, second is time how
       long still screen should be displayed until openQA decides that system is booted and third is timeout how long
       it should wait for still screen to appear. Example usage: `$self->boot_to_login_screen("graphical_login", 30);`
       will wait until screen is not moving for 30 seconds and then checks, whether `graphical_login` needle is displayed.
- `anacondatest` should be used in tests where Anaconda is running. It uploads Anaconda logs (for example
`anaconda.log` or `packaging.log`) in `post_fail_hook()`. It also provides these convenient methods for Anaconda:
    - `root_console()` tries to login is as a root. It decides to what TTY to switch into and then calls `console_login()`
      for root. If you set `check` argument, it dies if it fails to log in. Example usage:
      after calling `$self->root_console(check=>1);`, console should be shown with root logged in.
    - `select_disks()` handles disk selecting. It have one optional argument - number of disks to select. It should be
      run when main Anaconda hub is displayed. It enters disk selection spoke and then ensures that required number of
      disks are selected. Additionally, if `$PARTITIONING` variable (set in Web UI) starts with `custom_`, it selects
      "custom partitioning" checkbox. Example usage: after calling `$self->select_disks(2);` from Anaconda main hub,
      installation destination spoke will be displayed and two attached disks will be selected for installation.
    - `custom_scheme_select()` is used for setting custom partitioning scheme (such as LVM). It should be called when
      custom partitioning spoke is displayed. You have to pass it name of partitioning scheme and needle
      `anaconda_part_scheme_$scheme` should exist. Example usage: `$self->custom_scheme_select("btrfs");` uses
      `anaconda_part_scheme_btrfs` to set partitioning scheme to Btrfs.
    - `custom_change_type()` is used to set different device types for specified partition (e. g. RAID). It should be
      called when custom partitioning spoke is displayed. You have to pass it type of partition and name of partition
      and needles `anaconda_part_select_$part` and `anaconda_part_device_type_$type` should exist. Example usage:
      `$self->custom_change_type("raid", "root");` uses `anaconda_part_select_root` and `anaconda_part_device_type_raid`
      needles to set RAID for root partition.
    - `custom_change_fs()` is used to set different file systems for specified partition. It should be
      called when custom partitioning spoke is displayed. You have to pass it filesystem name and name of partition
      and needles `anaconda_part_select_$part` and `anaconda_part_fs_$fs` should exist. Example usage:
      `$self->custom_change_fs("ext3", "root");` uses `anaconda_part_select_root` and `anaconda_part_fs_ext3` needles
      to set ext3 file system for root partition.
    - `custom_delete_part()` is used for deletion of previously added partitions in custom partitioning spoke. It should
      be called when custom partitioning spoke is displayed. You have to pass it partition name and needle
      `anaconda_part_select_$part` should exist. Example usage: `$self->custom_delete_part('swap');` uses
      `anaconda_part_select_swap` to delete previously added swap partition.
- `installedtest` should be used in tests that are running on installed system (either in postinstall phase
or in upgrade tests). It uploads `/var/log` in `post_fail_hook()`. It provides these functions:
    - `root_console()` tries to login is as a root. It switches to TTY that is set as an argument (default is TTY1)
      and then calls `console_login()` for root. If you set `check` argument, it dies if it fails to log in.
      Example usage: running `$self->root_console(tty=>2, check=>0);` results in TTY2 displayed with root logged
      in.
    - `check_release()` checks whether the installed release matches a given value. E.g. `check_release(23)`
      checks whether the installed system is Fedora 23. The value can be 'Rawhide' or a Fedora release number;
      often you will want to use `get_var('VERSION')`. Expects a console prompt to be active when it is called.

### New test development workflow

1. Select test from [this document](https://bitbucket.org/rajcze/openqa_fedora_tools/src/develop/PhaseSeparation.md) or from
[phabricator page](https://phab.qadevel.cloud.fedoraproject.org/maniphest/?statuses=open%28%29&projects=PHID-PROJ-epofbmazit3u2rndqccd#R)
2. Put each part of your test as a separate file into `tests/` directory, reimplementing `run()` method
and `test_flags()` method, inheriting from one of the classes mentioned above.
3. Set correct variables (so that all test parts you have made are executed) in [WebUI -> Test suites](https://localhost:8080/admin/test_suites).
4. Link your newly created Test suite to medium type in [WebUI -> Job groups](https://localhost:8080/admin/groups).
5. Run test (see [openqa_fedora_tools repository](https://bitbucket.org/rajcze/openqa_fedora_tools)).
6. Create needles (images) by using interactive mode and needles editor in WebUI.
7. Add new Job template and Test suite into `templates` file.
8. Add new Test suite and Test case into [`conf_test_suites.py`](https://bitbucket.org/rajcze/openqa_fedora_tools/src/develop/tools/openqa_trigger/conf_test_suites.py)
file in openqa_fedora_tools repository.
9. Mark your test in PhaseSeparation.md as done.
10. Open differential request via phabricator, set openqa_fedora as a project and repository.
