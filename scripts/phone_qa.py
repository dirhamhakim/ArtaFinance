"""Physical-device QA helper; only operates the explicitly selected USB phone.

UI actions use labels/bounds from a fresh Android accessibility dump. It never
starts an emulator, clears application data, or operates other phone apps except
Android's document picker invoked by Arta.
"""
import json
import pathlib
import re
import subprocess
import sqlite3
import sys
import time
import xml.etree.ElementTree as ET

ADB = r'C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe'
SERIAL = 'R9RX200AM3W'
OUT = pathlib.Path(__file__).resolve().parents[1] / 'build' / 'physical-device'
OUT.mkdir(parents=True, exist_ok=True)


def adb(*args, binary=False):
    result = subprocess.run([ADB, '-s', SERIAL, *args], capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode('utf-8', errors='replace'))
    return result.stdout if binary else result.stdout.decode('utf-8', errors='replace')


def state(name='current'):
    fresh = False
    for attempt in range(3):
        result = adb('shell', 'uiautomator', 'dump', '/sdcard/arta-qa.xml')
        if 'dumped' in result:
            fresh = True
            break
        time.sleep(1)
    if not fresh:
        raise RuntimeError('No fresh accessibility tree; refusing stale UI actions')
    data = adb('exec-out', 'cat', '/sdcard/arta-qa.xml', binary=True)
    # System pickers can display account names. Keep those out of QA artifacts.
    safe_xml = re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '[account]', data.decode('utf-8'))
    (OUT / (name + '.xml')).write_text(safe_xml, encoding='utf-8')
    root = ET.fromstring(data)
    nodes = [dict(n.attrib) for n in root.iter('node')]
    packages = {n.get('package') for n in nodes}
    if not packages.intersection({'id.arta.arta', 'com.google.android.documentsui', 'com.android.documentsui'}):
        raise RuntimeError('Unexpected foreground UI: ' + str(packages))
    return nodes


def show(name='current'):
    nodes = state(name)
    for n in nodes:
        label = n.get('text') or n.get('content-desc')
        if label:
            item = json.dumps({k: n.get(k) for k in ['text', 'content-desc', 'class', 'resource-id', 'clickable', 'bounds']}, ensure_ascii=False)
            print(re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '[account]', item))
    return nodes


def tap(pattern, index=0):
    nodes = state()
    choices = [n for n in nodes if re.search(pattern, n.get('text', '') + '\n' + n.get('content-desc', ''))]
    if not choices:
        raise RuntimeError('No UI label matches ' + pattern)
    node = choices[index]
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node['bounds']))
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))
    time.sleep(0.35)


def fill(pattern, value, index=0):
    nodes = state()
    choices = [n for n in nodes if n.get('class') == 'android.widget.EditText' and re.search(pattern, n.get('text', '') + '\n' + n.get('content-desc', ''))]
    if not choices:
        raise RuntimeError('No text field matches ' + pattern)
    node = choices[index]
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node['bounds']))
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))
    # Android's keycombination Ctrl+A is not reliably delivered to Flutter's
    # EditableText on this device. Move to end and delete the observed value.
    adb('shell', 'input', 'keyevent', '123')
    old_length = len(node.get('text', ''))
    if node.get('password') == 'true':
        old_length = max(old_length, 80)
    adb('shell', 'input', 'keyevent', *(['67'] * (old_length + 2)))
    adb('shell', 'input', 'text', value.replace(' ', '%s'))
    hide_keyboard()
    time.sleep(0.2)


def hide_keyboard():
    # Samsung Keyboard does not dismiss on ESC. Back dismisses the IME, but
    # would navigate away if it were already hidden, so check its real state.
    status = adb('shell', 'dumpsys', 'input_method')
    if re.search(r'mInputShown=true', status):
        adb('shell', 'input', 'keyevent', '4')
        time.sleep(0.35)


def settings_idle():
    for _ in range(30):
        nodes = state()
        if any(n.get('content-desc') == 'Pulihkan dari file'
               and n.get('enabled') == 'true' for n in nodes):
            return
        time.sleep(0.5)
    raise RuntimeError('Settings still busy after waiting for native I/O')


def cancel_picker():
    # Back first navigates up folders in DocumentsUI. Continue until the picker
    # actually returns to Arta, and never send Back once Arta is foreground.
    for _ in range(10):
        nodes = state()
        if any(n.get('package') == 'id.arta.arta' for n in nodes):
            settings_idle()
            return
        if not any(n.get('package') in {'com.google.android.documentsui', 'com.android.documentsui'} for n in nodes):
            raise RuntimeError('Unexpected surface while cancelling file picker')
        hide_keyboard()
        adb('shell', 'input', 'keyevent', '4')
        time.sleep(0.5)
    raise RuntimeError('Document picker did not close')


def screenshot(name):
    (OUT / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))


def database(name):
    """Read a snapshot while UI is idle; never write to the phone database."""
    path = OUT / (name + '.sqlite')
    path.write_bytes(adb('exec-out', 'run-as', 'id.arta.arta', 'cat', 'files/arta.sqlite', binary=True))
    connection = sqlite3.connect(str(path))
    result = {}
    for table in ['accounts', 'ledger_transactions', 'schedules', 'schedule_occurrences']:
        result[table] = [json.loads(row[0]) for row in connection.execute('SELECT body FROM ' + table)]
    result['preferences'] = dict(connection.execute('SELECT key, value FROM preferences'))
    result['integrity'] = connection.execute('PRAGMA integrity_check').fetchone()[0]
    connection.close()
    (OUT / (name + '.json')).write_text(json.dumps(result, indent=2), encoding='utf-8')
    return result


def scroll(down=True):
    hide_keyboard()
    # Swipe inside the current app's observed full-screen view, away from system bars.
    nodes = state()
    roots = [n for n in nodes if n.get('package') in {
        'id.arta.arta', 'com.google.android.documentsui', 'com.android.documentsui'}]
    if not roots:
        raise RuntimeError('Scroll only supported in Arta or its document picker')
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', roots[0]['bounds']))
    x = (x1 + x2) // 2
    top, bottom = y1 + (y2-y1)//3, y1 + (y2-y1)*3//4
    adb('shell', 'input', 'swipe', str(x), str(bottom if down else top), str(x), str(top if down else bottom), '350')
    time.sleep(0.4)


def pick_file(filename):
    # Match the filename itself, not a separate native preview icon.
    pattern = '^' + re.escape(filename) + r'\n$'
    for attempt in range(12):
        nodes = state()
        candidates = [n for n in nodes if n.get('text') == filename]
        if candidates:
            box = list(map(int, re.findall(r'\d+', candidates[0]['bounds'])))
            height = max(int(re.findall(r'\d+', n['bounds'])[-1]) for n in nodes)
            # DocumentsUI can expose a clipped row behind the system navigation
            # bar. Reveal the whole label before tapping it.
            if box[1] > height * 0.15 and box[3] < height * 0.94:
                tap(pattern)
                return
            scroll(down=box[3] >= height * 0.94)
        else:
            scroll(down=attempt >= 2)
    raise RuntimeError('File not visible in document picker: ' + filename)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    action = sys.argv[1] if len(sys.argv) > 1 else 'show'
    if action == 'show':
        show(sys.argv[2] if len(sys.argv) > 2 else 'current')
    elif action == 'tap':
        tap(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 0)
        show()
    elif action == 'fill':
        fill(sys.argv[2], sys.argv[3])
        show()
    elif action == 'shot':
        screenshot(sys.argv[2])
