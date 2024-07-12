#!/usr/bin/python3

# Copyright Red Hat
#
# This file is part of os-autoinst-distri-fedora.
#
# os-autoinst-distri-fedora is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Adam Williamson <awilliam@redhat.com>
# Modified: Trevor Cooper <tcooper@rockylinux.org>

"""This is an openQA template loader/converter for FIF, the Fedora Intermediate Format. It reads
from one or more files expected to contain FIF JSON-formatted template data; read on for details
on this format as it compares to the upstream format. It produces data in the upstream format; it
can write this data to a JSON file and/or call the upstream loader on it directly, depending on
the command-line arguments specified.

The input data must contain definitions of Machines, Products, TestSuites, and Profiles. The input
data *may* contain JobTemplates, but does not have to and is expected to contain none or only a few
oddballs.

The format for Machines, Products and TestSuites is based on the upstream format but with various
quality-of-life improvements. Upstream, each of these is a list-of-dicts, each dict containing a
'name' key. This loader expects each to be a dict-of-dicts, with the names as keys (this is both
easier to read and easier to access). In the upstream format, each Machine, Product and TestSuite
dict can contain an entry with the key 'settings' which defines variables. The value (for some
reason...) is a list of dicts, each dict of the format {"key": keyname, "value": value}. This
loader expects a more obvious and simple format where the value of the 'settings' key is simply a
dict of keys and values.

The expected format of the Profiles dict is a dict-of-dicts. For each entry, the key is a unique
name, and the value is a dict with keys 'machine' and 'product', each value being a valid name from
the Machines or Products dict respectively. The name of each profile can be anything as long as
it's unique.

For TestSuites, this loader then expects an additional 'profiles' key in each dict, whose value is
a dict indicating the Profiles from which we should generate one or more job templates for that
test suite. For each entry in the dict, the key is a profile name from the Profiles dict, and the
value is the priority to give the generated job template.

This loader will generate JobTemplates from the combination of TestSuites and Profiles. It means
that, for instance, if you want to add a new test suite and run it on the same set of images and
arches as several other tests are already run, you do not need to do a large amount of copying and
pasting to create a bunch of JobTemplates that look a lot like other existing JobTemplates but with
a different test_suite value; you can just specify an appropriate profiles dict, which is much
shorter and easier and less error-prone. Thus specifying JobTemplates directly is not usually
needed and is expected to be used only for some oddball case which the generation system does not
handle.

The loader will automatically set the group_name for each job template based on Fedora-specific
logic which we previously followed manually when creating job templates (e.g. it is set to 'Fedora
PowerPC' for compose tests run on the PowerPC arch); thus this loader is not really generic but
specific to Fedora conventions. This could possibly be changed (e.g. by allowing the logic for
deciding group names to be configurable) if anyone else wants to use it.

Multiple input files will be combined. Mostly this involves simply updating dicts, but there is
special handling for TestSuites to allow multiple input files to each include entries for 'the
same' test suite, but with different profile dicts. So for instance one input file may contain a
complete TestSuite definition, with the value of its `profiles` key as `{'foo': 10}`. Another input
file may contain a TestSuite entry with the same key (name) as the complete definition in the other
file, and the value as a dict with only a `profiles` key (with the value `{'bar': 20}`). This
loader will combine those into a single complete TestSuite entry with the `profiles` value
`{'foo': 10, 'bar': 20}`.
"""

import argparse
import json
import os
import subprocess
import sys

import jsonschema

SCHEMAPATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'schemas')

def schema_validate(instance, fif=True, complete=True, schemapath=SCHEMAPATH):
    """Validate some input against one of our JSON schemas. We have
    'complete' and 'incomplete' schemas for FIF and the upstream
    template format. The 'complete' schemas expect the validated
    input to contain a complete set of data (everything needed for
    an openQA deployment to actually run tests). The 'incomplete'
    schemas expect the validated input to contain at least *some*
    valid data - they are intended for validating input files which
    will be combined into 'complete' data, or which will be loaded
    without --clean, to add to an existing configuration.
    """
    filename = 'openqa-'
    if fif:
        filename = 'fif-'
    if complete:
        filename += 'complete.json'
    else:
        filename += 'incomplete.json'
    base_uri = "file://{0}/".format(schemapath)
    resolver = jsonschema.RefResolver(base_uri, None)
    schemafile = os.path.join(schemapath, filename)
    with open(schemafile, 'r') as schemafh:
        schema = json.load(schemafh)
    # raises an exception if it fails
    jsonschema.validate(instance=instance, schema=schema, resolver=resolver)
    return True

# you could refactor this just using a couple of dicts, but I don't
# think that would really make it *better*
# pylint:disable=too-many-locals, too-many-branches
def merge_inputs(inputs, validate=False, clean=False):
    """Merge multiple input files. Expects JSON file names. Optionally
    validates the input files before merging, and the merged output.
    Returns a 5-tuple of machines, products, profiles, testsuites and
    jobtemplates (the first four as dicts, the fifth as a list).
    """
    machines = {}
    products = {}
    profiles = {}
    testsuites = {}
    jobtemplates = []

    for _input in inputs:
        try:
            with open(_input, 'r') as inputfh:
                data = json.load(inputfh)
        # we're just wrapping the exception a bit, so this is fine
        # pylint:disable=broad-except
        except Exception as err:
            print("Reading input file {} failed!".format(_input))
            sys.exit(str(err))
        # validate against incomplete schema
        if validate:
            schema_validate(data, fif=True, complete=False)

        # simple merges for all these
        for (datatype, tgt) in (
                ('Machines', machines),
                ('Products', products),
                ('Profiles', profiles),
                ('JobTemplates', jobtemplates),
        ):
            if datatype in data:
                if datatype == 'JobTemplates':
                    tgt.extend(data[datatype])
                else:
                    tgt.update(data[datatype])
        # special testsuite merging as described in the docstring
        if 'TestSuites' in data:
            for (name, newsuite) in data['TestSuites'].items():
                try:
                    existing = testsuites[name]
                    # combine and stash the profiles
                    existing['profiles'].update(newsuite['profiles'])
                    combinedprofiles = existing['profiles']
                    # now update the existing suite with the new one, this
                    # will overwrite the profiles
                    existing.update(newsuite)
                    # now restore the combined profiles
                    existing['profiles'] = combinedprofiles
                except KeyError:
                    testsuites[name] = newsuite

    # validate combined data, against complete schema if clean is True
    # (as we'd expect data to be loaded with --clean to be complete),
    # incomplete schema otherwise
    if validate:
        merged = {}
        if machines:
            merged['Machines'] = machines
        if products:
            merged['Products'] = products
        if profiles:
            merged['Profiles'] = profiles
        if testsuites:
            merged['TestSuites'] = testsuites
        if jobtemplates:
            merged['JobTemplates'] = jobtemplates
        schema_validate(merged, fif=True, complete=clean)
        print("Input template data is valid")

    return (machines, products, profiles, testsuites, jobtemplates)

def generate_job_templates(products, profiles, testsuites):
    """Given machines, products, profiles and testsuites (after
    merging, but still in intermediate format), generates job
    templates and returns them as a list.
    """
    jobtemplates = []
    for (name, suite) in testsuites.items():
        if 'profiles' not in suite:
            print("Warning: no profiles for test suite {}".format(name))
            continue
        for (profile, prio) in suite['profiles'].items():
            jobtemplate = {'test_suite_name': name, 'prio': prio}
            # x86_64 compose
            jobtemplate['group_name'] = 'Rocky'
            jobtemplate['machine_name'] = profiles[profile]['machine']
            product = products[profiles[profile]['product']]
            jobtemplate['arch'] = product['arch']
            jobtemplate['flavor'] = product['flavor']
            jobtemplate['distri'] = product['distri']
            jobtemplate['version'] = product['version']
            if jobtemplate['machine_name'] == 'ppc64le':
                if 'updates' in product['flavor']:
                    jobtemplate['group_name'] = "Rocky PowerPC Updates"
                else:
                    jobtemplate['group_name'] = "Rocky PowerPC"
            elif jobtemplate['machine_name'] in ('s390x'):
                if 'updates' in product['flavor']:
                    jobtemplate['group_name'] = "Rocky s390x Updates"
                else:
                    jobtemplate['group_name'] = "Rocky s390x"
            elif jobtemplate['machine_name'] in ('aarch64', 'ARM'):
                if 'updates' in product['flavor']:
                    jobtemplate['group_name'] = "Rocky AArch64 Updates"
                else:
                    jobtemplate['group_name'] = "Rocky AArch64"
            elif 'updates' in product['flavor']:
                # x86_64 updates
                jobtemplate['group_name'] = "Rocky Updates"
            jobtemplates.append(jobtemplate)
    return jobtemplates

def reverse_qol(machines, products, testsuites):
    """Reverse all our quality-of-life improvements in Machines,
    Products and TestSuites. We don't do profiles as only this loader
    uses them, upstream loader does not. We don't do jobtemplates as
    we don't do any QOL stuff for that. Returns the same tuple it's
    passed.
    """
    # first, some nested convenience functions
    def to_list_of_dicts(datadict):
        """Convert our nice dicts to upstream's stupid list-of-dicts-with
        -name-keys.
        """
        converted = []
        for (name, item) in datadict.items():
            item['name'] = name
            converted.append(item)
        return converted

    def dumb_settings(settdict):
        """Convert our sensible settings dicts to upstream's weird-ass
        list-of-dicts format.
        """
        converted = []
        for (key, value) in settdict.items():
            converted.append({'key': key, 'value': value})
        return converted

    # drop profiles from test suites - these are only used for job
    # template generation and should not be in final output. if suite
    # *only* contained profiles, drop it
    for suite in testsuites.values():
        del suite['profiles']
    testsuites = {name: suite for (name, suite) in testsuites.items() if suite}

    machines = to_list_of_dicts(machines)
    products = to_list_of_dicts(products)
    testsuites = to_list_of_dicts(testsuites)
    for datatype in (machines, products, testsuites):
        for item in datatype:
            if 'settings' in item:
                item['settings'] = dumb_settings(item['settings'])

    return (machines, products, testsuites)

def parse_args(args):
    """Parse arguments with argparse."""
    parser = argparse.ArgumentParser(description=(
        "Alternative openQA template loader/generator, using a more "
        "convenient input format. See docstring for details. "))
    parser.add_argument(
        '-l', '--load', help="Load the generated templates into openQA.",
        action='store_true')
    parser.add_argument(
        '--loader', help="Loader to use with --load",
        default="/usr/share/openqa/script/load_templates")
    parser.add_argument(
        '-w', '--write', help="Write the generated templates in JSON "
        "format.", action='store_true')
    parser.add_argument(
        '--filename', help="Filename to write with --write",
        default="generated.json")
    parser.add_argument(
        '--host', help="If specified with --load, gives a host "
        "to load the templates to. Is passed unmodified to upstream "
        "loader.")
    parser.add_argument(
        '-c', '--clean', help="If specified with --load, passed to "
        "upstream loader and behaves as documented there.",
        action='store_true')
    parser.add_argument(
        '-u', '--update', help="If specified with --load, passed to "
        "upstream loader and behaves as documented there.",
        action='store_true')
    parser.add_argument(
        '--no-validate', help="Do not do schema validation on input "
        "or output data", action='store_false', dest='validate')
    parser.add_argument(
        'files', help="Input JSON files", nargs='+')
    return parser.parse_args(args)

def run(args):
    """Read in arguments and run the appropriate steps."""
    args = parse_args(args)
    if not args.validate and not args.write and not args.load:
        sys.exit("--no-validate specified and neither --write nor --load specified! Doing nothing.")
    (machines, products, profiles, testsuites, jobtemplates) = merge_inputs(
        args.files, validate=args.validate, clean=args.clean)
    jobtemplates.extend(generate_job_templates(products, profiles, testsuites))
    (machines, products, testsuites) = reverse_qol(machines, products, testsuites)
    # now produce the output in upstream-compatible format
    out = {}
    if jobtemplates:
        out['JobTemplates'] = jobtemplates
    if machines:
        out['Machines'] = machines
    if products:
        out['Products'] = products
    if testsuites:
        out['TestSuites'] = testsuites
    if args.validate:
        # validate generated data against upstream schema
        schema_validate(out, fif=False, complete=args.clean)
        print("Generated template data is valid")
    if args.write:
        # write generated output to given filename
        with open(args.filename, 'w') as outfh:
            json.dump(out, outfh, indent=4)
    if args.load:
        # load generated output with given loader (defaults to
        # /usr/share/openqa/script/load_templates)
        loadargs = [args.loader]
        if args.host:
            loadargs.extend(['--host', args.host])
        if args.clean:
            loadargs.append('--clean')
        if args.update:
            loadargs.append('--update')
        loadargs.append('-')
        subprocess.run(loadargs, input=json.dumps(out), text=True, check=True)

def main():
    """Main loop."""
    try:
        run(args=sys.argv[1:])
    except KeyboardInterrupt:
        sys.stderr.write("Interrupted, exiting...\n")
        sys.exit(1)

if __name__ == '__main__':
    main()

# vim: set textwidth=100 ts=8 et sw=4:
