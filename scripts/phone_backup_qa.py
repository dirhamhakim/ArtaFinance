"""Continue the prepared, local-file-only Samsung backup QA session.

Requires the QA fixtures/backups made during this session. Refuses restoration
when any current account or transaction is not explicitly labelled QA.
"""
import json
import re
import sys
import time

import phone_qa as q


def wait_for(predicate, description):
    for _ in range(35):
        nodes = q.state()
        if predicate(nodes):
            return nodes
        time.sleep(0.5)
    raise RuntimeError('Timed out: ' + description)


def snapshot(name):
    q.settings_idle()
    data = q.database(name)
    if any(not a['name'].startswith('QA ') for a in data['accounts']):
        raise RuntimeError('Non-QA account found; refusing destructive test')
    if any(not t['category'].startswith('QA ') for t in data['ledger_transactions']):
        raise RuntimeError('Non-QA transaction found; refusing destructive test')
    return data


def local_folder():
    nodes = q.state()
    if not any(n.get('text') == 'Arta-QA-20261119'
               and n.get('resource-id', '').endswith('/breadcrumb_text') for n in nodes):
        q.tap('Tampilkan root')
        q.tap(r'^Download\n$')
        q.tap('Arta-QA-20261119')


def open_backup(filename):
    q.tap('Pulihkan dari file')
    local_folder()
    q.pick_file(filename)


def restore(filename, recovery, password=None, cancel_recovery=False):
    snapshot('native-before-' + re.sub(r'\W', '-', recovery))
    open_backup(filename)
    if password:
        wait_for(lambda ns: any(n.get('content-desc') == 'Buka backup' for n in ns), 'password dialog')
        q.fill('.*', password)
        q.tap(r'^\nLanjut$')
    wait_for(lambda ns: any(n.get('content-desc') == 'Pulihkan backup?' for n in ns), 'restore preview')
    q.tap('Simpan cadangan & pulihkan')
    wait_for(lambda ns: any(n.get('class') == 'android.widget.EditText'
                           and n.get('resource-id') == 'android:id/title' for n in ns), 'save recovery picker')
    if cancel_recovery:
        q.cancel_picker()
    else:
        q.fill('.*', recovery)
        q.tap(r'^SIMPAN\n$')
    q.settings_idle()


result_path = q.OUT / 'native-file-tests.json'
results = json.loads(result_path.read_text(encoding='utf-8')) if result_path.exists() else []


def passed(case, actual):
    results.append({'id': case, 'status': 'PASS', 'actual': actual})
    (q.OUT / 'native-file-tests.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(case, actual, flush=True)


def main():
    q.cancel_picker()
    resume_cancel = '--resume-cancel' in sys.argv
    initial = (json.loads((q.OUT / 'native-after-picker-cancellation.json').read_text(encoding='utf-8'))
               if resume_cancel else snapshot('native-ui-baseline'))
    assert len(initial['accounts']) == 5 and not initial['ledger_transactions']

    if not resume_cancel and '--skip-encrypted' not in sys.argv:
        restore('QA-NativeEncrypted.json', 'QA-EncryptedRecovery.json', password='ArtaUji2026!')
        assert snapshot('native-after-encrypted-restore') == initial
        passed('D05', 'Native encrypted restore with correct password matches baseline; earlier short/mismatch/wrong-password checks passed.')

    if not resume_cancel:
        q.tap('Ekspor JSON biasa')
        q.cancel_picker()
        q.settings_idle()
        q.tap('Pulihkan dari file')
        q.cancel_picker()
        assert snapshot('native-after-picker-cancellation') == initial
        restore('QA-AfterMarker.json', 'QA-BeforeCancelMarker.json')
    marker = snapshot('native-before-recovery-cancel')
    assert len(marker['ledger_transactions']) == 1
    restore('QA-NativeFull.json', 'cancel-recovery', cancel_recovery=True)
    assert snapshot('native-after-recovery-cancel') == marker
    q.state('native-recovery-cancellation-message')
    errors = {}
    for filename in ['arta-backup-rusak-uji.json', 'arta-backup-versi-tidak-didukung.json']:
        open_backup(filename)
        q.settings_idle()
        nodes = q.state('native-rejected-' + filename)
        errors[filename] = [n.get('content-desc') for n in nodes
                            if n.get('content-desc') and
                            re.search('Unexpected|Format|versi|JSON|backup|rusak', n['content-desc'])]
        assert snapshot('native-data-preserved-' + filename) == marker
    (q.OUT / 'native-rejection-messages.json').write_text(json.dumps(errors, indent=2), encoding='utf-8')
    passed('D06', 'Export/import cancellation, mandatory recovery cancellation, malformed JSON and unsupported version preserve data and keep UI usable.')

    restore('arta-backup-v1-uji.json', 'QA-BeforeLegacy.json')
    legacy = snapshot('native-legacy-restored')
    assert len(legacy['accounts']) == 1 and len(legacy['ledger_transactions']) == 1
    assert legacy['accounts'][0]['opening_minor'] == '-100000'
    assert legacy['ledger_transactions'][0]['amount_minor'] == '10000'
    assert legacy['preferences']['theme'] == 'light'
    q.tap(r'Akun\nTab 2')
    q.state('native-legacy-minus-1100')
    q.screenshot('native-legacy-minus-1100')
    q.tap(r'Pengaturan\nTab 4')
    restore('QA-NativeFull.json', 'QA-AfterLegacy.json')
    assert snapshot('native-back-to-full-v2') == initial
    passed('D07', 'Native v1 restore yields one account at -1100 and light theme; native v2 restore returns exactly to 5-account baseline.')

    restore('QA-BeforeUI.json', 'QA-AfterAll.json')
    empty = snapshot('native-final-empty')
    assert not empty['accounts'] and not empty['ledger_transactions']
    assert not empty['schedules'] and not empty['schedule_occurrences']
    q.tap(r'Ringkasan\nTab 1')
    q.state('native-final-overview')
    q.screenshot('native-final-overview')
    passed('D08', 'Original empty application state restored through native file picker; test accounts removed and recovery file retained.')


if __name__ == '__main__':
    main()
