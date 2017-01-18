openQA tests for the Fedora distribution
========================================

This repository contains tests and images for testing [Fedora](https://getfedora.org/) with [openQA](http://os-autoinst.github.io/openQA/). For additional tools, Installation Guide and Docker images, see [this repository](https://bitbucket.org/rajcze/openqa_fedora_tools).

Issues
------

For the present, issues (and pull requests) are tracked in [Phabricator](https://phab.qa.fedoraproject.org/). You can open issues against the `openqa_fedora` project [here](https://phab.qa.fedoraproject.org/maniphest/task/edit/form/default/?tags=openqa_fedora).

Test development
----------------
See official documentation on:

* [basic concept](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc)
* [test development (including API specification)](https://github.com/os-autoinst/openQA/blob/master/docs/WritingTests.asciidoc)
* [needles specification](https://github.com/os-autoinst/os-autoinst/blob/master/doc/needles.txt)
* [supported variables for backend](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backend_vars.asciidoc).

See [this example repo](https://github.com/os-autoinst/os-autoinst-distri-example) on how tests should be structured.

### main.pm modular architecture

Since openQA uses only one entrypoint for all tests (main.pm), we have decided to utilize this feature and make tests modular. It means that basic passing through main.pm (without any variables set) results in most basic installation test executed. Developer can customize it with additional variables (for example by setting `PACKAGE_SET=minimal` to do installation only with minimal package set).

Make your test modular, so that it utilizes `_boot_to_anaconda.pm`, `_software_selection.pm` and `_do_install_and_reboot.pm` tests (that are loaded automatically). Break your test into smaller parts, each dealing with one specific feature (e. g. partitioning, user creation...) and add their loading into main.pm based on reasonable variable setting (so they can be used in other tests also).

Fedora installation (and consequently main.pm) consists of several parts:

#### Booting into Anaconda or booting live image and starting Anaconda

Since there isn't much variation between tests in this step, we have developed universal `_boot_to_anaconda.pm` test that is loaded automatically each time except when `ENTRYPOINT` or `UPGRADE` is set (see VARIABLES.md).

To customize this step, you can set following variables:

- `GRUB` is appended to kernel line before boot. You can set for example `inst.updates` here.
- If `KICKSTART` is set, this part of installation ends here (program doesn't wait for Anaconda to appear). Note that you should set `inst.ks` yourself by setting `GRUB` variable.
- If `LIVE` is set, program waits for desktop to appear and then clicks on "Install to Hard Drive" button.

#### Customizing installation by interacting with Anaconda spokes

Most of the differences between tests take place in this part. If you want to add another installation test, you will probably put your variable checking and test loading here. All tests in this part should start on Anaconda's main hub and after they done its part, they should go back to Anaconda's main hub so that next test could be executed. In this phase, universal `_software_selection.pm` test is loaded that handles selecting what software to install.

To customize this step, you can set following variables:

- Set `PACKAGE_SET` to install required package set on "Software selection spoke" - you have to provide correct needles with the name of `anaconda_${PACKAGE_SET}_highlighted` and `anaconda_${PACKAGE_SET}_selected`.
- Set `ENCRYPT_PASSWORD` to encrypt disk, value of this variable is used as an actual password.

#### Installing Fedora and waiting for Fedora to reboot

After all customizations are finished, `_do_install_and_reboot.pm` test is automatically loaded. It starts installation, creates user and sets root password when required, waits for installation to finish and reboots into installed system. Only variables that control flow in this part are these:

- `ROOT_PASSWORD` to set root password to this value.
- When set, `USER_LOGIN` and `USER_PASSWORD` are used to create user in Anaconda.

#### Post-install phase

After installation is finished and installed system is fully booted, you can run additional tests as checks that installed system has correct attributes - that correct file system is used, that RAID is used etc.

### Test inheritance

Your test can inherit from `basetest`, `installedtest` or `anacondatest`. Each provides relevant methods that are documented in-line, so read the files (`lib/anacondatest.pm`, `lib/installedtest.pm`) for information on these.

- `basetest`: A base class provided by os-autoinst - it has empty `post_fail_hook()` and doesn't set any flags.
- `anacondatest`: should be used in tests where Anaconda is running. It uploads Anaconda logs (for example `anaconda.log` or `packaging.log`) in `post_fail_hook()`.
- `installedtest`: should be used in tests that are running on installed system (either in postinstall phase or in upgrade tests).

There are also several modules that export utility functions, currently `utils`, `anaconda`, `freeipa`, `packagetest` and `tapnet`. Your test can `use` any of these modules and then directly call the functions they export. Again, the functions are documented in-line.

### New test development workflow

1. Select test from [phabricator page](https://phab.qa.fedoraproject.org/w/openqa/tests/).
2. Put each part of your test as a separate file into `tests/` directory, reimplementing `run()` method
and `test_flags()` method, inheriting from one of the classes mentioned above.
3. Set correct variables (so that all test parts you have made are executed) in [WebUI -> Test suites](https://localhost:8080/admin/test_suites).
4. Link your newly created Test suite to medium type in [WebUI -> Job groups](https://localhost:8080/admin/groups).
5. Run test (see [openqa_fedora_tools repository](https://bitbucket.org/rajcze/openqa_fedora_tools)).
6. Create needles (images) by using interactive mode and needles editor in WebUI.
7. Add new Job template and Test suite into `templates` file.
8. Add new Test suite and Test case into [`conf_test_suites.py`](https://bitbucket.org/rajcze/openqa_fedora_tools/src/develop/tools/openqa_trigger/conf_test_suites.py)
file in openqa_fedora_tools repository.
9. Open differential request via phabricator, set openqa_fedora as a project and repository.
10. Mark your test in [phabricator page](https://phab.qa.fedoraproject.org/w/openqa/tests/) as done.

### Language handling

Tests can run in different languages. To set the language which will be used for a test, set the `LANGUAGE` variable for the test suite. The results of this will be:

1. The value set will be typed into the language search box in anaconda.
2. Any needle with at least one tag that starts with `LANGUAGE` will be unregistered unless it has the tag `LANGUAGE-(LANGUAGE)` (where `(LANGUAGE)` is the value set, forced to upper-case).
3. As a consequence, the chosen language will be selected at the anaconda Welcome screen.

It is very important, therefore, that needles have the correct tags. Any needle which is expected to match for tests run in *any* language must have no `LANGUAGE` tags. Other needles must have the appropriate tag(s) for the languages they are expected to match. The safest option if you are unsure is to set no `LANGUAGE` tag(s). The only danger of this is that missing translations may not be caught.

Note that tags of the form `ENV-INSTLANG-(anything)` are useless artefacts and should be removed.
