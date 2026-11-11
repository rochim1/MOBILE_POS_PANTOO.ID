"""Build the reviewed POS ID/EN catalog; rejects missing or changed parameters."""
import collections
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / 'output/pos-i18n-20261110'
L10N = ROOT / 'lib/l10n'
work = json.loads((OUT / 'candidates.json').read_text(encoding='utf-8'))
reuse = json.loads((OUT / 'reuse.json').read_text(encoding='utf-8'))
reviewed = {}
for file in sorted((OUT / 'batches').glob('*.txt')):
    for line in file.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        number, text = line.split('|', 1)
        number = int(number)
        if number in reviewed:
            raise ValueError(f'Duplicate work item {number}')
        reviewed[number] = text.replace(r'\n', '\n')
assert set(reviewed) == {row['index'] for row in work}, 'Incomplete translation worklist'
catalog = dict(reuse)
excluded = []
for row in work:
    text = reviewed[row['index']]
    if text == '__SKIP__':
        excluded.append(row)
        continue
    source = row['source']
    catalog[source] = source if text == '__KEEP__' else text
catalog['Masuk'] = 'Sign In'
catalog['Izin'] = 'Permission'
supplemental_path = L10N / 'supplemental_ui.json'
if supplemental_path.exists():
    catalog.update(json.loads(supplemental_path.read_text(encoding='utf-8')))

def params(value):
    return re.findall(r'\{(arg\d+)\}', value)

def icu(value):
    # Only argN tokens are application parameters. Receipt-template braces are literal.
    result = []
    for part in re.split(r'(\{arg\d+\})', value):
        if re.fullmatch(r'\{arg\d+\}', part):
            result.append(part)
        else:
            escaped = part.replace("'", "''")
            result.append("'" + escaped + "'" if '{' in part or '}' in part else escaped)
    return ''.join(result)

messages = {'id': {'@@locale': 'id'}, 'en': {'@@locale': 'en'}}
aliases = {}
rows = []
id_overrides = json.loads((L10N / 'id_overrides.json').read_text(encoding='utf-8'))
english_aliases = {}
for source, english in sorted(catalog.items()):
    assert collections.Counter(params(source)) == collections.Counter(params(english)), f'Changed parameters: {source!r} -> {english!r}'
    key = 'pos' + hashlib.sha1(source.encode()).hexdigest()[:12]
    assert key not in aliases, 'Translation key collision'
    aliases[key] = source
    english_aliases[key] = english
    indonesian = id_overrides.get(source, source)
    metadata = {'description': 'Reviewed Pantoo POS UI copy; do not use for user-generated data'}
    names = list(dict.fromkeys(params(source)))
    if names:
        metadata['placeholders'] = {name: {'type': 'String'} for name in names}
    for code, text in [('id', indonesian), ('en', english)]:
        messages[code][key] = icu(text)
        messages[code]['@'+key] = metadata
    rows.append({'key': key, 'source': source, 'id': indonesian, 'en': english})

extra = {
    'receiptCustomerLabel': ('Pelanggan', 'Customer'),
    'stockMovementIn': ('Masuk', 'Stock In'),
    'stockMovementOut': ('Keluar', 'Stock Out'),
    'languageTitle': ('Bahasa', 'Language'),
    'languageSystem': ('Ikuti perangkat', 'Use device language'),
    'languageSaveFailed': ('Pilihan bahasa belum tersimpan. Coba lagi.', 'Language preference could not be saved. Try again.'),
    'signInAction': ('Masuk', 'Sign In'),
}
for key, (id_text, en_text) in extra.items():
    for code, text in [('id', id_text), ('en', en_text)]:
        messages[code][key] = icu(text)
        messages[code]['@'+key] = {'description': 'Contextual stock, language, and authentication UI'}
for code in messages:
    (L10N / f'app_{code}.arb').write_text(json.dumps(messages[code], ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(L10N / 'legacy_ui_aliases.json').write_text(json.dumps(aliases, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(L10N / 'english_ui_aliases.json').write_text(json.dumps(english_aliases, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(OUT / 'translations.json').write_text(json.dumps({'entries': rows, 'excluded': excluded}, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
with (OUT / 'catalog-id-en.csv').open('w', encoding='utf-8-sig', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['key', 'Indonesia', 'English'])
    writer.writerows((row['key'], row['id'], row['en']) for row in rows)
print(f'{len(rows)+len(extra)} paired locale keys; {len(excluded)} technical/data-only entries excluded.')
