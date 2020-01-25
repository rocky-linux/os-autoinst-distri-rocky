# FIF and openQA template schemas

This directory contains [JSON Schema](https://json-schema.org/) format schemas for the FIF and
upstream openQA template data formats. `fif-complete.json` and `fif-incomplete.json` are the FIF
schemas; `openqa-complete.json` and `openqa-incomplete.json` are the upstream schemas. The
'complete' schemas expect the input to contain a *complete* set of template data (enough for an
openQA instance to schedule and run tests); the *incomplete* schemas expect the input to contain
only *some* valid template data (these may be files that will be combined into complete data, or
files intended to be loaded without `--clean` only as supplementary data to an openQA deployment
with existing data). The other files are subcomponents of the schemas that are loaded by reference.
