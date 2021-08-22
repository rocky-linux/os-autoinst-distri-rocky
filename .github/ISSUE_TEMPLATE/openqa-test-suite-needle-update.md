---
name: openQA test suite / needle update
about: This template provide basis for general case submission of issue to resolve
  openQA test failure via test and/or needle updates
title: Test suite failure for [insert_test_suite_name_here] on [DISTRI-VERSION-FLAVOR-ARCH]
labels: ''
assignees: ''

---

## Describe Issue

Please describe the issue as completely as possible so that an appropriate fix may be developed.

| Test Suite | `<please_insert_test_suite_name_here>` |
|---|---|
| Result | <please_insert_previous_test_result_here> |
| Scheduled product | `<please_inster_the_schedule_product_here>` |
| Test module | `<full_path_to_test_module_to_be_fixed>` |
| Analysis | *<insert_error_message_produced_in_test>*<br><insert_any_additional_details_that_may_assist_in_resolution> |

## Planned Action
- Please provide suggested resolution steps if they are know.

## Special Notes
- Please provide any special instructions/information that may help testing progress more quickly. For example... Test can run from `disk_64bit_cockpit.qcow2` image if it is saved and stored appropriately in the test system. There is no need to run from beginning and/or trigger from `install_default_upload@64bit`.
