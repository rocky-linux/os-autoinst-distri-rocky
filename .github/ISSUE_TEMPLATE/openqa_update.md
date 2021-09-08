---
name: openQA test suite and/or needle update
about: Report openQA test failure and/or needle update requirement
title: [Test Suite Failure] for [insert_test_suite_name_here] on [DISTRI-VERSION-FLAVOR-ARCH]
labels: [test suite]
assignees: ''

---

## Describe Issue

Please describe the issue as completely as possible so that an appropriate fix may be developed.

| Test Suite        | <!-- eg: `install_default@uefi` --> |
|-------------------|-------------------------------------|
| Result            | <!-- eg: **failed** ( 04:46 minutes ) --> |
| Scheduled product | <!-- eg: `rocky-8.4-dvd-iso-x86_64` --> |
| Test module       | <!-- eg: `/var/lib/openqa/share/tests/rocky/tests/_impacted_test_module_here.pm` --> |
| Analysis          | <!-- eg: *Analysis	Test died: no candidate needle with tag(s) 'anaconda_help_progress_link' matched* --> |

<!-- Provide any additional relevant detail here -->

## Planned Action
<!-- Outline the steps that should be taken to address this issue -->

## Special Notes
<!-- Please provide any special instructions/information that may help testing progress more quickly -->
<!-- For example... Test can run from `disk_64bit_cockpit.qcow2` image if it is saved and stored appropriately in the test system. There is no need to run from beginning and/or trigger from `install_default_upload@64bit`. -->
