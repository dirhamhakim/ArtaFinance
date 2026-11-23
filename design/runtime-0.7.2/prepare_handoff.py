import json, zipfile, math, hashlib, re
from pathlib import Path

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[1]
registry=json.loads((BASE/'screen-manifest.json').read_text(encoding='utf-8-sig'))
plan=json.loads((BASE/'manifest-plan.json').read_text(encoding='utf-8-sig'))
native=json.loads(zipfile.ZipFile(ROOT/'design/Arta-0.7.2-Seluruh-Tampilan.figcraft').read('document.json'))
nodes=native['nodes']
bykey={(v['route'],v['theme']):v for v in registry}
commands=[];links=[];missing=[];decor=[]

def readunit(r):return json.loads((BASE/'units'/r['file']).read_text(encoding='utf-8'))['commands']
for r in registry:
    unit=readunit(r);aliases=r['aliases'];names={c.get('as'):c.get('params',{}).get('name') for c in unit if c.get('as')}
    if r.get('sheet'):
        for c in unit:
            pa=c.get('params',{});a=c.get('as');nid=aliases.get(a)
            if not nid:continue
            if pa.get('name')=='Underlying app preview' or (pa.get('name')=='Arta' and pa.get('x')==32 and pa.get('y')==130):
                decor.append({'command':'edit.delete','params':{'ids':[nid]}})
            if pa.get('name','').endswith(' · bottom sheet'):
                height=min(752,max(220,r['contentHeight']+104));decor.append({'command':'node.set','params':{'ids':[nid],'props':{'y':852-height,'height':height}}})
            if pa.get('name')=='Scroll viewport':
                height=min(752,max(220,r['contentHeight']+104));decor.append({'command':'node.set','params':{'ids':[nid],'props':{'height':height-88}}})
        decor.append({'command':'node.set','params':{'ids':[r['id']],'props':{'fill':None}}})
    # Every link names an actual route. Theme menu can cross between paired roots.
    for link in r['links']:
        nid=aliases.get(link['node']);dest=link['dest'];theme=r['theme']
        if not nid:missing.append({'route':r['route'],'alias':link['node']});continue
        if dest in ['@close','@back']:
            action={'type':'closeOverlay' if r.get('sheet') else 'back'}
        else:
            if r['route']=='theme-picker' and names.get(link['node'])=='Terang':theme='Light'
            if r['route']=='theme-picker' and names.get(link['node'])=='Gelap':theme='Dark'
            target=bykey.get((dest,theme))
            if not target:missing.append({'route':r['route'],'dest':dest});continue
            if target.get('sheet'):
                action={'type':'openOverlay','dest':target['id'],'position':'center','close_on_outside':True,'background':'#00000000'}
            else:action={'type':'navigate','dest':target['id']}
        params={'id':nid,'trigger':{'type':'onClick'},'action':action,'transition':{'type':'dissolve'},'durationMs':160}
        if r.get('sheet') and action['type']=='navigate':
            params.pop('action');params['actions']=[{'type':'closeOverlay'},action]
        links.append({'command':'proto.interaction.add','params':params})
    # Exact current theme text rather than displaying all three values together.
    if r['route']=='settings':
        for c in unit:
            if c.get('params',{}).get('props',{}).get('characters')=='Gelap / Terang / Ikuti perangkat':
                decor.append({'command':'node.set','params':{'ids':[aliases[c['as']]],'props':{'characters':'Gelap' if r['theme']=='Dark' else 'Terang'}}})
    # Setup uses an app bar with Back; full-page unlock intentionally has none.
    if r['route'] in ['pin-setup','pin-confirm','pin-mismatch','pin-reset']:
        for c in unit:
            if c.get('params',{}).get('props',{}).get('characters')=='PIN Arta':
                decor.append({'command':'node.set','params':{'ids':[aliases[c['as']]],'props':{'x':56,'width':292}}})
    if r['route'].startswith('pin'):
        setup=r['route'] in ['pin-setup','pin-confirm','pin-mismatch','pin-reset']
        body=next((aliases[c['as']] for c in unit if c.get('params',{}).get('name')=='Konten scroll · seluruh field aplikasi'),None)
        if body:decor.append({'command':'node.create','params':{'type':'frame','name':'Field PIN 6 angka · border accent','parent':body,'index':0,'x':0,'y':138 if setup else 236,'width':368,'height':52,'select':False,'props':{'fill':None,'stroke':{'$var':'Accent'},'strokeWeight':1,'cornerRadius':4}}})
    # ProviderLogo in the app uses a white circle with 6px interior padding.
    for c in unit:
        pa=c.get('params',{});comp=pa.get('component')
        if c['command']=='instance.create' and comp in [221,231,237,245,263,266,277,285,291,294,307,322]:
            inst=aliases.get(c.get('as'));current=nodes.get(str(inst),{})
            par=current.get('parent');pn=nodes.get(str(par),{});ht=pn.get('height',72)
            if inst and par:
                decor.append({'command':'node.create','params':{'type':'ellipse','name':'ProviderLogo · white circle','parent':par,'index':0,'x':16,'y':ht/2-20,'width':40,'height':40,'select':False,'props':{'fill':'#FFFFFF'}}})
                decor.append({'command':'transform.scale','params':{'ids':[inst],'factor':.7}})
                decor.append({'command':'node.set','params':{'ids':[inst],'props':{'x':22,'y':ht/2-current.get('height',20)*.7/2}}})

if missing:raise SystemExit(json.dumps({'unresolved':missing},ensure_ascii=False))

flows=[]
for route,label in [('home','Ringkasan'),('home-empty','Awal penggunaan'),('assets','Aset'),('transactions','Transaksi'),('portfolio','Investasi'),('analysis-combined','Analisis'),('performance','Saham vs IHSG'),('schedules','Berulang & cicilan'),('staking','Staking'),('interest','Bunga'),('catalog','Katalog IDX'),('market','Harga & kurs'),('categories','Kategori 0.7.2'),('settings','Pengaturan & backup'),('pin','Kunci aplikasi')]:
    for theme in ['Dark','Light']:
        flows.append({'command':'proto.flow.add','params':{'start':bykey[(route,theme)]['id'],'name':f'0.7.2 · {label} · {theme}'}})
for p in native['pages']:
    if p<10:
        for f in nodes[str(p)].get('flows',[]):commands.append({'command':'proto.flow.remove','params':{'start':f['start']}})
commands+=decor+flows
for r in registry:
    if r['route']=='startup-loading':links.append({'command':'proto.interaction.add','params':{'id':r['id'],'trigger':{'type':'afterDelay','ms':960},'action':{'type':'navigate','dest':bykey[('home',r['theme'])]['id']},'transition':{'type':'dissolve'},'durationMs':160}})
    if r['route']=='pin-biometric-loading':links.append({'command':'proto.interaction.add','params':{'id':r['id'],'trigger':{'type':'afterDelay','ms':500},'action':{'type':'navigate','dest':bykey[('biometric-dialog',r['theme'])]['id']}}})

for prefix,steps in [('polish',commands),('prototype',links)]:
    folder=BASE/prefix;folder.mkdir(exist_ok=True)
    for i in range(0,len(steps),140):
        (folder/f'{i//140:03d}.json').write_text(json.dumps({'document':3,'label':f'0.7.2 · {prefix} {i//140+1}','commands':steps[i:i+140]},ensure_ascii=False),encoding='utf-8')

counts={}
for r in registry:counts[r['page']]=counts.get(r['page'],0)+1
summary={'app_version':'0.7.2+11','dated':'2026-11-22','states':len(registry)//2,'artboards':len(registry),'pages':counts,'prototype_interactions':len(links),'flow_starts':len(flows),'polish_commands':len(commands),'unresolved':missing,'library_pages':9,'app_pages':13}
(BASE/'coverage-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
