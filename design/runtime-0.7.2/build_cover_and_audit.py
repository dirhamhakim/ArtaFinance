import json, zipfile, math, hashlib
from pathlib import Path
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[1]
reg=json.loads((BASE/'screen-manifest.json').read_text(encoding='utf-8-sig'))
summary=json.loads((BASE/'coverage-summary.json').read_text(encoding='utf-8'))
page=json.loads((BASE/'pages.json').read_text(encoding='utf-8-sig'))['Panduan']
C=[];index=0
def cmd(command,params,a=None):
 d={'command':command,'params':params}
 if a:d['as']=a
 C.append(d);return {'$ref':a}
def node(typ,name,parent,x,y,w,h,**props):
 global index
 index+=1;return cmd('node.create',dict(type=typ,name=name,parent=parent,x=x,y=y,width=w,height=h,props=props,select=False),'c'+str(index))
def text(t,x,y,w,size=16,bold=False,role='Text/Primary',parent=None):
 return node('text',t[:90],parent or cover,x,y,w,math.ceil(size*1.5),characters=t,fontFamily='Bit Sans',fontStyle='Bold' if bold else 'Regular',fontSize=size,lineHeight=size*1.5,textAutoResize='height',fill={'$var':role})
def rect(name,x,y,w,h,parent=None,fill='Surface/Raised'):
 return node('frame',name,parent or cover,x,y,w,h,fill={'$var':fill},cornerRadius=12)
def link(n,dest):cmd('proto.interaction.add',{'id':n,'action':{'type':'navigate','dest':dest}})
cover=node('frame','START HERE · Arta 0.7.2 · 22 Nov 2026',page,0,0,1280,1740,fill={'$var':'Background'},clip=True)
cmd('variable.setMode',{'ids':[cover],'collection':'Theme','mode':'Dark'})
logo=cmd('instance.create',{'component':6773,'parent':cover,'x':64,'y':54},'logo')
text('Arta 0.7.2',184,48,1000,38,True)
text('Seluruh tampilan & fitur aplikasi Android',184,108,1000,22,True)
text('Snapshot kode 0.7.2+11 · 22 November 2026 · satu file native FigCraft',64,160,1150,15,role='Text/Secondary')
for i,(large,label) in enumerate([('286','state dan percabangan'),('572','artboard · Dark + Light'),('30','titik awal prototype')]):
 r=rect(label,64+i*392,210,368,112);text(large,20,12,320,34,True,'Accent',r);text(label,20,68,320,14,False,'Text/Secondary',r)
for theme,x in [('Dark',64),('Light',368)]:
 r=rect('Mulai '+theme,x,350,280,54,fill='Accent/Button');text('Mulai tema '+('gelap' if theme=='Dark' else 'terang'),20,16,240,14,True,'OnAccent',r)
 link(r,next(v['id'] for v in reg if v['route']=='home' and v['theme']==theme))
text('Peta seluruh layar aplikasi',64,448,724,24,True)
groups=[('Ringkasan','01 · Ringkasan & Analisis','home'),('Aset','02 · Aset, Debit & Utang','assets'),('Transaksi','03 · Transaksi & Lampiran','transactions'),('Berulang','04 · Berulang & Cicilan','schedules'),('Investasi','05 · Investasi & IHSG','portfolio'),('Staking','06 · Staking Crypto','staking'),('Bunga','07 · Bunga & Bagi Hasil','interest'),('Katalog','08 · Katalog IDX & Instrumen','catalog'),('Harga','09 · Harga & Kurs','market'),('Kategori','10 · Kategori 0.7.2','categories'),('Pengaturan','11 · Pengaturan & Backup','settings'),('Keamanan','12 · Keamanan & Pembukaan','pin'),('Pemilih','13 · Pemilih & Android','calendar')]
for i,(key,label,route) in enumerate(groups):
 r=rect(label,64,506+i*56,724,46);text(label,16,11,565,15,True,parent=r);text(str(summary['pages'][key])+' frame',598,12,110,13,role='Text/Secondary',parent=r)
 link(r,next(v['id'] for v in reg if v['route']==route and v['theme']=='Dark'))
right=rect('Cara meninjau',832,448,384,360)
text('Cara meninjau',20,20,344,20,True,parent=right)
text('1. Buka halaman berawalan APP.\n2. Pasangan Dark di kiri, Light di kanan.\n3. Gulir viewport untuk melihat seluruh field.\n4. Jalankan prototype dari titik awal alur.\n5. Klik baris indeks untuk masuk ke alurnya.\n\nHalaman LIB menyimpan ikon, logo, kontrol dan contoh komposisi master; bukan daftar fitur tambahan APK.',20,64,344,15,parent=right)
right=rect('Batas prototype',832,832,384,346)
text('Batas prototype',20,20,344,20,True,parent=right)
text('Teks dan kontrol dapat diedit. Chart berupa vektor, bukan screenshot utuh.\n\nAngka, harga dan tanggal merupakan data contoh. Input, perhitungan keuangan, API, file picker dan sensor tidak dijalankan oleh FigCraft.\n\nLayar sistem Android adalah representasi alur; tampilannya mengikuti versi/perangkat pengguna.',20,62,344,15,parent=right)
r=rect('Font & sumber implementasi',64,1280,1152,168)
text('Font & sumber implementasi',24,20,1100,20,True,parent=r)
text('Bit Sans Regular/Bold mengikuti asset aplikasi: assets/fonts/. Font dimuat pada sesi MCP; file native tidak menyematkan font. Editor lain memerlukan Bit Sans tersedia, atau gunakan PNG preview.\n\nSetiap artboard menyimpan route, tema, versi dan nama source pada pluginData. Daftar lengkap: design/runtime-0.7.2/CAKUPAN-LAYAR.md.',24,60,1100,15,parent=r)
r=rect('Cakupan dan status',64,1472,1152,204)
text('Cakupan dan status',24,20,1100,20,True,parent=r)
text('286 state × dua tema, 13 kelompok aplikasi, seluruh form screen utama, pemilih, sheet, konfirmasi, kondisi kosong/error, harga tersimpan, serta kategori terbaru.\n\nFile ini mendokumentasikan UI yang ada pada kode 0.7.2, bukan menambahkan fitur ke APK. Native Android, data/API dan perhitungan tetap diuji di aplikasi. Panduan dan laporan verifikasi tersedia di folder runtime-0.7.2.',24,62,1100,15,parent=r)
cmd('page.select',{'id':page});cmd('select.set',{'ids':[cover]}) if False else None
(BASE/'cover-batch.json').write_text(json.dumps({'document':3,'label':'Indeks lengkap Arta 0.7.2','commands':C},ensure_ascii=False),encoding='utf-8')

# Read-only geometry and link audit. Native ZIP was written only by MCP.
j=json.loads(zipfile.ZipFile(ROOT/'design/Arta-0.7.2-Seluruh-Tampilan.figcraft').read('document.json'));nodes=j['nodes']
rootids={r['id'] for r in reg};visited=set();issues=[];texts=0;vectors=0
def walk(nid,route):
 global texts,vectors
 if nid in visited:return
 visited.add(nid);n=nodes[str(nid)];texts+=n['type']=='text';vectors+=n['type']=='vector'
 for cid in n.get('children',[]):
  child=nodes.get(str(cid))
  if not child:continue
  if n['type']=='frame' and n.get('name') not in ['Scroll viewport','Konten scroll · seluruh field aplikasi'] and not n.get('name','').startswith('Isi card'):
   t=child.get('transform',[1,0,0,1,0,0]);x,y=t[4:6];w=child.get('width',0);h=child.get('height',0)
   if not(child.get('name','').startswith('Scrim') or child['type'] in ['vector','line','group'] or n['id'] in rootids):
    if x < -1 or y < -1 or x+w > n.get('width',0)+1 or y+h > n.get('height',0)+1:
     issues.append({'route':route,'id':cid,'name':child['name'],'parent':n['id'],'parentName':n['name'],'bounds':[x,y,w,h],'parentSize':[n.get('width',0),n.get('height',0)]})
  walk(cid,route)
for r in reg:walk(r['id'],r['route']+' / '+r['theme'])
invalid=[];count=0
for n in nodes.values():
 for interaction in n.get('interactions',[]):
  for a in interaction.get('actions',[]):
   count+=1
   if 'dest' in a and str(a['dest']) not in nodes:invalid.append({'source':n['id'],'action':a})
report={'app_artboards':len(rootids),'app_descendant_nodes':len(visited),'app_text_layers':texts,'app_vector_layers':vectors,'geometry_findings':len(issues),'findings':issues,'invalid_prototype_destinations':invalid,'all_document_actions':count,'notes':['Scrollable content intentionally extends viewport. Glyph vector/group bounds and full-screen scrims are excluded from containment checks.','A geometry finding is reviewed before being treated as a clipping defect.']}
(BASE/'qa-geometry.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['findings','notes']},ensure_ascii=False));print(json.dumps(issues[:20],ensure_ascii=False))
