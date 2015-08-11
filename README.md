OpenQA tests for the Fedora distribution
========================================

This repository contains tests and images for testing [Fedora](https://getfedora.org/) with
[OpenQA](http://os-autoinst.github.io/openQA/). For additional tools, Installation Guide and
Docker images, see [this repository](https://bitbucket.org/rajcze/openqa_fedora_tools).

Test development
----------------
See official documentation [on basic concept](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc),
[test development (including API specification)](https://github.com/os-autoinst/openQA/blob/master/docs/WritingTests.asciidoc),
[needles specification](https://github.com/os-autoinst/os-autoinst/blob/master/doc/needles.txt) and
[supported variables for backend](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backend_vars.asciidoc). See
[this example repo](https://github.com/os-autoinst/os-autoinst-distri-example) on how tests should be structured.

### main.pm modular architecture
Since OpenQA uses only one entrypoint for all tests (main.pm), we have decided to utilize
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
that will be useful during testing Fedora, like `console_login()` or `boot_to_login_screen()`. It should be used
when no other, more specific class can be used.
- `anacondatest` should be used in tests where Anaconda is running. It uploads Anaconda logs (for example
`anaconda.log` or `packaging.log`) in `post_fail_hook()`. It also provides convenient methods for Anaconda
like `select_disks()`.
- `installedtest` should be used in tests that are running on installed system (either in postinstall phase
or in upgrade tests). It uploads `/var/log` in `post_fail_hook()`.

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
