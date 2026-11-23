"""USB-only Arta QA commands. No emulator; no changes to other financial apps."""
import datetime
import json
import pathlib
import re
import sqlite3
import sys
import time
import xml.etree.ElementTree as ET

import phone_qa as q

sys.stdout.reconfigure(encoding='utf-8')
q.OUT = pathlib.Path(__file__).resolve().parents[1] / 'build' / 'physical-device-0.7.1'
q.OUT.mkdir(parents=True, exist_ok=True)
PACKAGES = {'id.arta.arta', 'com.google.android.documentsui', 'com.android.documentsui',
            'com.google.android.photopicker',
            'com.google.android.providers.media.module', 'com.android.providers.media.module',
            'com.android.systemui'}


def clean(value):
    value = re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '[account]', value)
    return re.sub(r'CG-[\w-]{12,}', '[api-key]', value)


def state(name='current'):
    for _ in range(3):
        if 'dumped' in q.adb('shell', 'uiautomator', 'dump', '/sdcard/arta-qa.xml'):
            break
        time.sleep(.5)
    else:
        raise RuntimeError('No fresh UI; refusing stale actions')
    xml = q.adb('exec-out', 'cat', '/sdcard/arta-qa.xml')
    nodes = [dict(n.attrib) for n in ET.fromstring(xml).iter('node')]
    if not any(n.get('package') in PACKAGES for n in nodes):
        raise RuntimeError('Foreground is outside Arta and its invoked system pickers')
    (q.OUT / (name + '.xml')).write_text(clean(xml), encoding='utf-8')
    return nodes


q.state = state


def show(name='current'):
    nodes = state(name)
    for n in nodes:
        label = n.get('text') or n.get('content-desc')
        if label:
            print(clean(json.dumps({k: n.get(k) for k in ['text','content-desc','class','resource-id','clickable','enabled','bounds']}, ensure_ascii=False)))
    return nodes


def wait_for(predicate, label, seconds=45):
    until = time.monotonic()+seconds
    while time.monotonic()<until:
        nodes = state()
        if predicate(nodes):
            return nodes
        time.sleep(.4)
    raise RuntimeError('Timeout: '+label)


def visible(pattern):
    return any(re.search(pattern,n.get('text','')+'\n'+n.get('content-desc','')) for n in state())


def reveal(pattern, down=True, attempts=12):
    previous = None
    reversed_once = False
    for _ in range(attempts):
        nodes = state()
        for node in nodes:
            if re.search(pattern, node.get('text','')+'\n'+node.get('content-desc','')):
                left, top, right, bottom = map(int, re.findall(r'\d+', node['bounds']))
                if bottom-top >= 40 and top >= 220 and bottom <= 2085:
                    return
        signature = [(n.get('text'),n.get('content-desc'),n['bounds']) for n in nodes]
        if signature == previous and not reversed_once:
            down = not down
            reversed_once = True
        previous = signature
        q.scroll(down)
    raise RuntimeError('Cannot reveal '+pattern)


def read_database(name='current-data'):
    file=q.OUT/(name+'.sqlite')
    file.write_bytes(q.adb('exec-out','run-as','id.arta.arta','cat','files/arta.sqlite',binary=True))
    with sqlite3.connect(file) as c:
        data={t:[json.loads(r[0]) for r in c.execute('SELECT body FROM '+t)]
              for t in ['accounts','ledger_transactions','schedules','schedule_occurrences','payment_cards','finance_extras']}
        data['integrity']=c.execute('pragma integrity_check').fetchone()[0]
        data['preferences']={k:v for k,v in c.execute('select key,value from preferences')
                             if k in {'theme','amounts_hidden','market_daily_auto'}}
    (q.OUT/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    return data


def record(case,actual,status='PASS'):
    file=q.OUT/'manual-results.json'
    rows=json.loads(file.read_text(encoding='utf-8')) if file.exists() else []
    rows=[r for r in rows if r['id']!=case]
    rows.append({'id':case,'status':status,'actual':actual,'at':datetime.datetime.now().isoformat()})
    file.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    print(case,status,actual,flush=True)


def local_folder():
    if any(n.get('text')=='Arta-QA-20261121' and n.get('resource-id','').endswith('/breadcrumb_text') for n in state()):
        return
    q.tap('Tampilkan root')
    q.tap(r'^Download\n$')
    q.tap(r'^Arta-QA-20261121\n$')


def save_as(name):
    wait_for(lambda ns:any(n.get('resource-id')=='android:id/title' and n.get('class')=='android.widget.EditText' for n in ns),'save picker')
    local_folder()
    q.fill('.*',name)
    q.tap(r'^SIMPAN\n$')


def restore(name,recovery='QA-Before-Restore.json'):
    q.tap('Pulihkan dari file')
    local_folder();q.pick_file(name)
    wait_for(lambda ns:any(n.get('content-desc')=='Pulihkan backup?' for n in ns),'restore preview',seconds=90)
    q.tap('Simpan cadangan & pulihkan');save_as(recovery)
    q.settings_idle()


if __name__=='__main__':
    action=sys.argv[1] if len(sys.argv)>1 else 'show'
    if action=='show': show(sys.argv[2] if len(sys.argv)>2 else 'current')
    elif action=='tap': q.tap(sys.argv[2]);show()
    elif action=='fill': q.fill(sys.argv[2],sys.argv[3]);show()
    elif action=='scroll': q.scroll(len(sys.argv)<3 or sys.argv[2]!='up');show()
    elif action=='back': q.adb('shell','input','keyevent','4');time.sleep(.4);show()
    elif action=='screenshot': q.screenshot(sys.argv[2]);state(sys.argv[2])
    elif action=='database':
        d=read_database(sys.argv[2] if len(sys.argv)>2 else 'current-data')
        print(json.dumps({k:len(v) if isinstance(v,list) else v for k,v in d.items()}))
    elif action=='restore': restore(sys.argv[2]);show()
    else: raise ValueError('Unknown QA command')
