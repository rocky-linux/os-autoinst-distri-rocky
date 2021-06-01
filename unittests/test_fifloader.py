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

# these are all kinda inappropriate for pytest patterns
# pylint: disable=no-init, protected-access, no-self-use, unused-argument

"""Tests for fifloader.py."""

# core imports
import json
import os
import tempfile
from unittest import mock

# third party imports
import jsonschema.exceptions
import pytest

# internal imports
import fifloader

DATAPATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'data')

def _get_merged(input1='templates.fif.json', input2='templates-updates.fif.json'):
    """Convenience function as multiple tests need to do this."""
    return fifloader.merge_inputs(
        [os.path.join(DATAPATH, input1), os.path.join(DATAPATH, input2)])

def test_schema_validate():
    """Test for schema_validate."""
    with open(os.path.join(DATAPATH, 'templates.fif.json'), 'r') as tempfh:
        tempdata = json.load(tempfh)
    with open(os.path.join(DATAPATH, 'templates-updates.fif.json'), 'r') as updfh:
        updata = json.load(updfh)
    assert fifloader.schema_validate(tempdata, fif=True, complete=True) is True
    assert fifloader.schema_validate(tempdata, fif=True, complete=False) is True
    assert fifloader.schema_validate(updata, fif=True, complete=False) is True
    with pytest.raises(jsonschema.exceptions.ValidationError):
        fifloader.schema_validate(updata, fif=True, complete=True)
    with pytest.raises(jsonschema.exceptions.ValidationError):
        fifloader.schema_validate(tempdata, fif=False, complete=True)
    with pytest.raises(jsonschema.exceptions.ValidationError):
        fifloader.schema_validate(tempdata, fif=False, complete=False)
    # we test successful openQA validation later in test_run

# we test merging in both orders, because it can work in one order
# but be broken in the other
@pytest.mark.parametrize(
    "input1, input2",
    [
        ('templates.fif.json', 'templates-updates.fif.json'),
        ('templates-updates.fif.json', 'templates.fif.json'),
    ]
)
def test_merge_inputs(input1, input2):
    """Test for merge_inputs."""
    (machines, products, profiles, testsuites, jobtemplates) = _get_merged(input1, input2)
    # a few known attributes of the test data to ensure the merge worked
    assert len(machines) == 2
    assert len(products) == 4
    assert len(profiles) == 4
    assert not jobtemplates
    # testsuite merging is the most complex feature
    # len should be 3 as there is 1 unique suite in each input file,
    # and one defined in both which should be merged
    assert len(testsuites) == 3
    # check the merged suite was merged correctly
    # we should have the profiles from *both* input files...
    assert len(testsuites['base_selinux']['profiles']) == 4
    # and we should still have the settings (note, combining settings
    # is not supported, the last-read settings dict is always used)
    assert len(testsuites['base_selinux']['settings']) == 6

def test_generate_job_templates():
    """Test for generate_job_templates."""
    (machines, products, profiles, testsuites, _) = _get_merged()
    templates = fifloader.generate_job_templates(products, profiles, testsuites)
    # we should get one template per profile in merged input
    assert len(templates) == 8
    for template in templates:
        assert template['group_name'] in ['fedora', 'Fedora PowerPC', 'Fedora AArch64',
                                          'Fedora Updates', 'Fedora PowerPC Updates',
                                          'Fedora AArch64 Updates']
        assert template['machine_name'] in list(machines.keys())
        assert isinstance(template['prio'], int)
        for item in ('arch', 'distri', 'flavor', 'version'):
            assert item in template
        assert template['test_suite_name'] in list(testsuites.keys())

def test_reverse_qol():
    """Test for reverse_qol."""
    (machines, products, _, testsuites, _) = _get_merged()
    (machines, products, testsuites) = fifloader.reverse_qol(machines, products, testsuites)
    assert isinstance(machines, list)
    assert isinstance(products, list)
    assert isinstance(testsuites, list)
    assert len(machines) == 2
    assert len(products) == 4
    assert len(testsuites) == 3
    settlists = []
    for datatype in (machines, products, testsuites):
        for item in datatype:
            # all items should have one of these
            settlists.append(item['settings'])
            # no items should have one of these
            assert 'profiles' not in item
    for settlist in settlists:
        assert isinstance(settlist, list)
        for setting in settlist:
            assert list(setting.keys()) == ['key', 'value']

def test_parse_args():
    """Test for parse_args."""
    args = fifloader.parse_args(['-l', '--host', 'https://openqa.example', '--clean', '--update',
                                 '--loader', '/tmp/newloader', 'foo.json', 'bar.json'])
    assert args.load is True
    assert args.host == 'https://openqa.example'
    assert args.clean is True
    assert args.update is True
    assert args.write is False
    assert args.loader == '/tmp/newloader'
    assert args.files == ['foo.json', 'bar.json']
    args = fifloader.parse_args(['-l', '-w', 'foo.json', 'bar.json'])
    assert args.load is True
    assert not args.host
    assert args.clean is False
    assert args.update is False
    assert args.write is True
    assert args.filename == 'generated.json'
    assert args.loader == '/usr/share/openqa/script/load_templates'
    assert args.files == ['foo.json', 'bar.json']
    args = fifloader.parse_args(['-w', '--filename', 'newout.json', 'foo.json'])
    assert args.load is False
    assert args.write is True
    assert args.filename == 'newout.json'
    assert args.files == ['foo.json']

@mock.patch('subprocess.run', autospec=True)
def test_run(fakerun):
    "Test for run()."""
    with pytest.raises(SystemExit, match=r".neither --write nor --load.*"):
        fifloader.run(['--no-validate', 'foo.json'])
    with pytest.raises(SystemExit) as excinfo:
        fifloader.run(['-l'])
        assert "arguments are required: files" in excinfo.message
    with tempfile.NamedTemporaryFile() as tempfh:
        # this will actually do everything and write out template data
        # parsed from the test inputs to the temporary file
        fifloader.run(['-w', '--filename', tempfh.name,
                       os.path.join(DATAPATH, 'templates.fif.json'),
                       os.path.join(DATAPATH, 'templates-updates.fif.json')])
        written = json.load(tempfh)
    # check written data matches upstream data schema
    assert fifloader.schema_validate(written, fif=False, complete=True) is True
    fifloader.run(['-l', '--loader', '/tmp/newloader', '--host',
                   'https://openqa.example', '--clean', '--update',
                   os.path.join(DATAPATH, 'templates.fif.json'),
                   os.path.join(DATAPATH, 'templates-updates.fif.json')])
    assert fakerun.call_count == 1
    assert fakerun.call_args[0][0] == ['/tmp/newloader', '--host', 'https://openqa.example',
                                       '--clean', '--update', '-']
    assert fakerun.call_args[1]['input'] == json.dumps(written)
    assert fakerun.call_args[1]['text'] is True

# vim: set textwidth=100 ts=8 et sw=4:
