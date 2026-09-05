#!/usr/bin/env python3
"""Check public Codex packaging without installing plugins or calling a model."""
import json
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / '.codex-plugin/plugin.json').read_text())
marketplace = json.loads((ROOT / '.agents/plugins/marketplace.json').read_text())
assert manifest['version'] == (ROOT / 'VERSION').read_text().strip(), 'Codex version != VERSION'
assert manifest['name'] == marketplace['plugins'][0]['name'] == 'erixpo-workflow'
assert manifest['skills'] == './skills/', 'Reuse the canonical portable skills'
assert list((ROOT / manifest['skills']).glob('*/SKILL.md')), 'No bundled skills'
entry = marketplace['plugins'][0]
assert entry['source'] == {
    'source': 'url',
    'url': 'https://github.com/erixpo/erixpo-workflow.git',
    'ref': 'main',
}, 'Public installs must resolve the published repository'
assert entry['policy'] == {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'}
assert entry['category']
for field in ('composerIcon', 'logo', 'logoDark'):
    value = manifest['interface'][field]
    asset = (ROOT / value).resolve()
    assert value.startswith('./assets/') and asset.is_relative_to(ROOT)
    assert asset.is_file(), f'Missing {field}'
    svg = ElementTree.parse(asset).getroot()
    assert svg.tag == '{http://www.w3.org/2000/svg}svg'
assert 1 <= len(manifest['interface']['defaultPrompt']) <= 3
print('ok Codex plugin metadata, public source, icon, and version')
