# openQA tests for the Fedora distribution

This repository contains tests and images for testing [Fedora](https://getfedora.org/) with [openQA](http://os-autoinst.github.io/openQA/). The [fedora_openqa library and CLI](https://pagure.io/fedora-qa/fedora_openqa) are used for scheduling tests, and [createhdds](https://pagure.io/fedora-qa/createhdds) is used for creating base disk images for the test. For openQA installation instructions, see [the Fedora openQA wiki page](https://fedoraproject.org/wiki/OpenQA).

## Issues

[Issues](https://pagure.io/fedora-qa/os-autoinst-distri-fedora/issues) and [pull requests](https://pagure.io/fedora-qa/os-autoinst-distri-fedora/pull-requests) are tracked in [os-autoinst-distri-fedora Pagure](https://pagure.io/fedora-qa/os-autoinst-distri-fedora). Pagure uses a Github-like pull request workflow, so if you're familiar with that, you can easily submit Pagure pull requests. If not, you can read up in the [Pagure documentation](https://docs.pagure.org/pagure/usage/index.html).

## Requirements

Obviously, this repository is little use without access to an openQA installation. Also, the tests themselves require the perl libraries JSON and REST::Client to be installed on the worker host; in Fedora, the package names are `perl-JSON` and `perl-REST-Client`. To load templates from this repository, you will need the upstream client tools (packaged as `openqa-client` in Fedora) and the dependencies of `fifloader.py` (see below for more on this tool) installed. Those dependencies are Python 3 and the `jsonschema` library. For running the unit tests, you will additionally need `pytest` and `tox`.

## Test development

See official documentation on:

* [basic concept](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc)
* [test development (including API specification)](https://github.com/os-autoinst/openQA/blob/master/docs/WritingTests.asciidoc)
* [needles specification](https://github.com/os-autoinst/os-autoinst/blob/master/doc/needles.txt)
* [supported variables for backend](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backend_vars.asciidoc).

See [this example repo](https://github.com/os-autoinst/os-autoinst-distri-example) on how tests should be structured.

### FIF template format

The test templates in this repository (files ending in `fif.json`) are not in the same format as expected by and are not directly compatible with the upstream template loader. They are in a format referred to as 'FIF' ('Fedora Intermediate Format') which is parsed into the upstream format by the `fifloader.py` utility found in this repository. This format is intended to be more convenient for human reading and editing. It is more fully explained in the docstring at the top of `fifloader.py`. Please refer to this when adding new tests to the templates. A command like `./fifloader.py --load templates.fif.json templates-updates.fif.json` can be used to load templates in the FIF format (this converts them to the upstream format, and calls the upstream template loader on the converted data). See `./fifloader.py -h` for further details on `fifloader.py`.

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

1. Put each part of your test as a separate file into `tests/` directory, reimplementing `run()` method
and `test_flags()` method, inheriting from one of the classes mentioned above.
2. Set correct variables (so that all test parts you have made are executed) in [WebUI -> Test suites](https://localhost:8080/admin/test_suites).
3. Link your newly created Test suite to medium type in [WebUI -> Job groups](https://localhost:8080/admin/groups).
4. Run test (see [fedora_openqa repository](https://pagure.io/fedora-qa/fedora_openqa)).
5. Create needles (images) by using interactive mode and needles editor in WebUI.
6. Add new test suite and profiles into `templates.fif.json` file (and/or `templates-updates.fif.json`, if the test is applicable to the update testing workflow)
7. Add new Test suite and Test case into [`conf_test_suites.py`](https://pagure.io/fedora-qa/fedora_openqa/blob/master/f/src/fedora_openqa/conf_test_suites.py) file in fedora_openqa repository.
8. Run `tox`. This will check the templates are valid.
9. Open pull request for the os-autoinst-distri-fedora changes in [Pagure](https://pagure.io/fedora-qa/os-autoinst-distri-fedora). Pagure uses a Github-style workflow (summary: fork the project via the web interface, push your changes to a branch on your fork, then use the web interface to submit a pull request). See the [Pagure documentation](https://docs.pagure.org/pagure/usage/index.html) for more details.
10. Open a pull request in [fedora_openqa Pagure](https://pagure.io/fedora-qa/fedora_openqa) for any necessary fedora_openqa changes.

### Language handling

Tests can run in different languages. To set the language which will be used for a test, set the `LANGUAGE` variable for the test suite. The results of this will be:

1. The value set will be typed into the language search box in anaconda.
2. Any needle with at least one tag that starts with `LANGUAGE` will be unregistered unless it has the tag `LANGUAGE-(LANGUAGE)` (where `(LANGUAGE)` is the value set, forced to upper-case).
3. As a consequence, the chosen language will be selected at the anaconda Welcome screen.

It is very important, therefore, that needles have the correct tags. Any needle which is expected to match for tests run in *any* language must have no `LANGUAGE` tags. Other needles must have the appropriate tag(s) for the languages they are expected to match. The safest option if you are unsure is to set no `LANGUAGE` tag(s). The only danger of this is that missing translations may not be caught.

Note that tags of the form `ENV-INSTLANG-(anything)` are useless artefacts and should be removed.

## Licensing and credits

The contents of this repository are available under the GPL, version 3 or any later version. A copy is included as COPYING. Note that we do not include the full GPL header in every single test file as they are quite short and this would waste a lot of space.

The tools and tests in this repository are maintained by the [Fedora QA team](https://fedoraproject.org/wiki/QA). We are grateful to the [openSUSE](https://opensuse.org) team for developing openQA, and for the [openSUSE tests](https://github.com/os-autoinst/os-autoinst-distri-opensuse) on which this repository was initially based (and from which occasional pieces are still borrowed).
