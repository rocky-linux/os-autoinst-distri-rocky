OpenQA tests for the Fedora distribution
========================================

This repository contains tests and images for testing [Fedora](https://getfedora.org/) with
[OpenQA](http://os-autoinst.github.io/openQA/). For additional tools, Installation Guide and
Docker images, see [this repository](https://bitbucket.org/rajcze/openqa_fedora_tools).

Test development
----------------
See official documentation [on basic concept](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc), [test development (including API specification)](https://github.com/os-autoinst/openQA/blob/master/docs/WritingTests.asciidoc), [needles specification](https://github.com/os-autoinst/os-autoinst/blob/master/doc/needles.txt) and [supported variables for backend](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backend_vars.asciidoc). See
[this example repo](https://github.com/os-autoinst/os-autoinst-distri-example) on how tests should be structured.

In short, since OpenQA uses only one entrypoint for all tests (`main.pm`), we have decided to utilize
this feature and make tests modular. It means that basic passing through `main.pm` (without any variables set)
results in most basic installation test executed. Developer can then customize it with additional variables
(for example by setting `PACKAGE_SET=minimal` to do installation only with minimal package set).

Make your test modular, so that it utilizes `_boot_to_anaconda()` and `_do_install_and_reboot()`
tests (that are loaded automatically). Break your test into smaller parts, each dealing with one
specific feature (e. g. partitioning, user creation...) and add their loading into `main.pm` based
on reasonable variable setting (so they can be used in other tests also).

### Test inheritance
Your test can inherit from `basetest`, `fedorabase`, `installedtest` or `anacondatest`.

* `basetest` is basic class provided by os-autoinst - it has empty `post_fail_hook()` and doesn't set any flags.
* `fedorabase` doesn't neither set flags nor does anything in `post_fail_hook()`, but it provides basic functions
that will be useful during testing Fedora, like `console_login()` or `boot_to_login_screen()`. It should be used
when no other, more specific class can be used.
* `anacondatest` should be used in tests where Anaconda is running. It uploads Anaconda logs (for example
`anaconda.log` or `packaging.log`) in `post_fail_hook()`. It also provides convenient methods for Anaconda
like `select_disks()`.
* `installedtest` should be used in tests that are running on installed system (either in postinstall phase
or in upgrade tests). It uploads `/var/log` in `post_fail_hook()`.

### Test development checklist

1. Select test from [this document](https://bitbucket.org/rajcze/openqa_fedora_tools/src/develop/PhaseSeparation.md) or from [phabricator page](https://phab.qadevel.cloud.fedoraproject.org/maniphest/?statuses=open%28%29&projects=PHID-PROJ-epofbmazit3u2rndqccd#R)
2. Put each part of your test as a separate file into `tests/` directory, reimplementing `run()` method
and `test_flags()` method, inheriting from one of the classes mentioned above.
3. Set correct variables (so that all test parts you have made are executed) in [WebUI -> Test suites](https://localhost:8080/admin/test_suites).
4. Link your newly created Test suite to medium type in [WebUI -> Job groups](https://localhost:8080/admin/groups).
5. Run test (see [openqa_fedora_tools repository](https://bitbucket.org/rajcze/openqa_fedora_tools)).
6. Create needles (images) by using interactive mode and needles editor in WebUI.
7. Add new Job template and Test suite into `templates` file.
8. Add new Test suite and Test case into [`conf_test_suites.py`](https://bitbucket.org/rajcze/openqa_fedora_tools/src/develop/tools/openqa_trigger/conf_test_suites.py) file in openqa_fedora_tools repository.
9. Mark your test in PhaseSeparation.md as done.
10. Open differential request via phabricator.
