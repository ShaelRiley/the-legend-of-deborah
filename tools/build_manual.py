#!/usr/bin/env python3
"""Build both renderings from one authored book and the final game catalog.

python3 tools/run_lua54.py tools/export_manual_catalog.lua
python3 tools/build_manual.py [--pdf /absolute/output.pdf] [--check]
"""
import argparse
import base64
import hashlib
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/manual'
TARGET = ROOT / 'gamemodes/legend_of_deborah/gamemode/lod/manual'
esc = html.escape


def chapters():
    book = json.loads((SOURCE / 'book.json').read_text())
    catalog = json.loads((SOURCE / 'catalog.json').read_text())
    feats = catalog['OrdinaryFeats']
    names = {k: v['displayName'] for k, v in feats.items()}
    families = {}
    for fid, feat in feats.items():
        families.setdefault(feat.get('featFamilyId', fid), []).append(feat)
    def clean(text):
        for fid in sorted(names, key=len, reverse=True):
            text = text.replace(fid, names[fid])
        return text.replace('featAbilityDelta.', 'permanent ').replace('FeatQualificationAbilities', 'permanent abilities').replace('FeatQualification', 'permanent')
    for family in sorted(families):
        entries = sorted(families[family], key=lambda f: (f.get('rankIndex', 0), f['displayName']))
        book['chapters'].append({'id': 'feat-'+family, 'title': entries[0]['displayName'], 'group': 'Feat reference', 'entries': [
            {'id': f['featId'], 'name': f['displayName'], 'requirement': clean(f.get('eligibilityText', '')),
             'text': clean(f['effectParams']['description']), 'actors': f.get('actorText', '')} for f in entries]})
    for cls, items in sorted(catalog['ClassCapstones'].items()):
        book['chapters'].append({'id': 'capstone-'+cls, 'title': cls.title()+' capstones', 'group': 'Level 20 reference', 'entries': [
            {'id': f['featId'], 'name': f['displayName'], 'requirement': cls.title()+' · Level 20 · choose one',
             'text': clean(f['effectParams']['description'])} for _, f in sorted(items.items())]})
    book['chapters'].append({'id': 'fallbacks', 'title': 'Fallback feats', 'group': 'Feat reference', 'entries': [
        {'id': f['featId'], 'name': f['displayName'], 'requirement': clean(f['eligibilityText']), 'text': clean(f['effectParams']['description'])}
        for _, f in sorted(catalog['FallbackFeats'].items())]})
    properties = catalog.get('EquipmentProperties', {})
    if properties:
        book['chapters'].append({'id': 'properties', 'title': 'Equipment property index', 'group': 'Equipment reference',
            'text': ['The item inspection gives the rolled amount. Percentage modifiers, flat ability/save points, fixed wards, and move grants are different units. A hit rider creates an attempt under the ordinary save rules.'],
            'rows': [[p['label'].replace('_',' ').title(), ('Only '+p['family']+'. ' if p.get('family') else '')+
                      ('Drawback only.' if p.get('drawbackOnly') else 'May be positive or a drawback.' if p.get('negative') else 'Benefit.')]
                     for _,p in sorted(properties.items())]})
    assert len(feats) == 135 and len(catalog['FallbackFeats']) == 6
    assert sum(map(len,catalog['ClassCapstones'].values())) == 9
    return book


CSS = '''
*{box-sizing:border-box}html,body{margin:0;height:100%;color:#202020;font-family:Arial,Helvetica,sans-serif;background:#243b59}
button,input,select{font:inherit}button,select{cursor:pointer}button{background:#fff;border:2px solid #1d426e;color:#173c6a;padding:8px 12px;font-weight:bold;border-radius:2px}button:focus,select:focus,input:focus{outline:3px solid #dc4b30;outline-offset:1px}button:disabled{opacity:.4;cursor:default}
#toolbar{position:absolute;top:0;left:0;width:100%;background:#f5f0df;padding:10px 14px;border-bottom:4px solid #ce3c2c;z-index:2;height:126px}
.line>*{margin-right:8px}.line>:last-child{margin-right:0}.line{display:flex;align-items:center;margin-bottom:7px}#contents{min-width:0;flex:1;padding:7px;max-width:100%}#search{min-width:60px;flex:1;padding:7px;border:1px solid #947f64}#status{font-size:12px;line-height:1.2;width:100%;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}#reader{position:absolute;top:126px;bottom:0;width:100%;overflow:auto;padding:24px 12px;scrollbar-color:#d69b49 #243b59}
.page{background:#fffdf7;max-width:680px;margin:0 auto;padding:32px 40px 34px;box-shadow:6px 7px 0 #132a45;font-size:18px;line-height:1.5;overflow-wrap:break-word;word-wrap:break-word;border-top:10px solid #d94732;display:none}.page.active{display:block}
.kicker{font-size:12px;color:#ac392d;font-weight:bold;letter-spacing:1.8px;text-transform:uppercase;border-bottom:1px solid #d8ccaf;padding-bottom:9px}h1,h2,h3{color:#1c4c85;line-height:1.08;font-weight:900;letter-spacing:-.7px}h1{font-size:52px}h2{font-size:36px;margin:17px 0}h3{font-size:24px;margin:20px 0 7px}p{margin:13px 0}ol{padding-left:28px}li{margin:12px 0;padding-left:5px}table{width:100%;border-collapse:collapse;margin:20px 0;font-size:.9em}td{vertical-align:top;padding:10px 8px;border-bottom:1px solid #d5cdbb}td:first-child{font-weight:bold;color:#194b82;width:36%}tr:nth-child(odd){background:#f6f0dc}blockquote{border:3px solid #1e446c;border-radius:16px;padding:14px 18px;font-weight:bold;color:#194b82;font-size:1.05em;margin:20px 0}
.art{background-repeat:no-repeat;background-color:white;margin:18px auto;width:240px;height:240px;max-width:100%}.wide-art{width:100%;height:auto}.cover{background:#f8d348;text-align:center;border-top:10px solid #fff}.cover h1{margin:8px 0 10px;text-transform:uppercase;text-shadow:2px 2px #fff;font-size:48px}.cover img{width:100%;max-height:530px;object-fit:contain}.cover .strap{display:inline-block;background:#193f70;color:white;padding:8px 14px;font-size:15px;letter-spacing:2px;font-weight:bold}.cover p{font-size:14px}.entry{border-top:3px solid #ce402e;padding-top:5px;margin-top:24px}.requirement{color:#a13527;font-size:.82em;font-weight:bold}.actors{font-size:.8em;color:#59584d}.folio{margin-top:25px;border-top:2px solid #214c7c;padding-top:8px;color:#214c7c;font-size:12px;font-weight:bold}
@media(max-width:540px){#toolbar{padding:8px;height:129px}#reader{top:129px;padding:12px 6px}.line>*{margin-right:4px}button{padding:8px;font-size:13px}#contents{font-size:13px}.page{padding:20px 18px;font-size:17px}h2{font-size:29px}.cover h1{font-size:37px}td{padding:8px 5px}.art{width:190px;height:190px}}
'''

JS = '''(function(){
var pages=document.querySelectorAll('.page'), current=0, scrolls={}, font=18, query='', results=[], match=0;
var reader=document.getElementById('reader'), select=document.getElementById('contents');
function call(name){try{if(window.lod&&typeof window.lod[name]==='function'){window.lod[name].apply(window.lod,Array.prototype.slice.call(arguments,1));}}catch(e){}}
function remember(){scrolls[current]=reader.scrollTop;call('position',current,reader.scrollTop,font);}
function show(n,top){n=Math.max(0,Math.min(pages.length-1,parseInt(n,10)||0));remember();pages[current].className=pages[current].className.replace(' active','');current=n;pages[current].className+=' active';select.value=String(n);reader.scrollTop=typeof top==='number'?top:(scrolls[n]||0);document.getElementById('prev').disabled=n===0;document.getElementById('next').disabled=n===pages.length-1;document.getElementById('status').textContent=(n+1)+' / '+pages.length+' · '+pages[n].getAttribute('data-title');remember();}
function scale(n){font=Math.max(15,Math.min(26,n));for(var i=0;i<pages.length;i++)pages[i].style.fontSize=font+'px';remember();}
document.getElementById('prev').onclick=function(){show(current-1);};document.getElementById('next').onclick=function(){show(current+1);};select.onchange=function(){show(this.value);};
document.getElementById('smaller').onclick=function(){scale(font-1);};document.getElementById('larger').onclick=function(){scale(font+1);};
function find(){var q=document.getElementById('search').value.toLowerCase().replace(/^\\s+|\\s+$/g,'');if(!q)return;if(query!==q){results=[];match=0;query=q;for(var i=0;i<pages.length;i++)if((pages[i].textContent||pages[i].innerText).toLowerCase().indexOf(q)!==-1)results.push(i);}else if(results.length)match=(match+1)%results.length;if(results.length){show(results[match],0);document.getElementById('status').textContent='Match '+(match+1)+' of '+results.length+' · '+pages[current].getAttribute('data-title');}else document.getElementById('status').textContent='No match. Try another word.';}
document.getElementById('find').onclick=find;document.getElementById('search').onkeydown=function(e){if(e.keyCode===13){find();e.preventDefault();}};
reader.onscroll=remember;document.onkeydown=function(e){e=e||window.event;var tag=(e.target||e.srcElement).tagName;if(e.keyCode===27){call('close');e.preventDefault();return;}if(tag==='INPUT'||tag==='SELECT'||tag==='TEXTAREA')return;if(e.keyCode===37){show(current-1);e.preventDefault();}else if(e.keyCode===39){show(current+1);e.preventDefault();}else if(e.keyCode===80||e.keyCode===73||e.keyCode===76){call('tab',e.keyCode);e.preventDefault();}};
window.LODManual={restore:function(n,top,size){scale(parseInt(size,10)||18);show(n,Math.max(0,Number(top)||0));},go:show};
show(0,0);call('ready');
})();'''


def make_html(book):
    uris = {n: 'data:image/jpeg;base64,'+base64.b64encode((SOURCE/'art'/ (n+'.jpg')).read_bytes()).decode() for n in ('cover','deborah','bosses')}
    pages = ['<article class="page cover" data-title="Cover"><div class="kicker">Expanded instruction booklet</div><h1>The Legend<br>of Deborah</h1><div class="strap">RESCUE HER. AGAIN.</div><img alt="Deborah with her crowbar above the container prison" src="'+uris['cover']+'"><p>'+esc(book['edition'])+'</p></article>']
    for chapter in book['chapters']:
        s = '<article class="page" id="'+esc(chapter['id'])+'" data-title="'+esc(chapter['title'],quote=True)+'"><div class="kicker">'+esc(chapter.get('group','How to play'))+'</div><h2>'+esc(chapter['title'])+'</h2>'
        art = chapter.get('art','')
        if art.startswith('deborah:'):
            pose = int(art.split(':')[1]);s += '<div role="img" aria-label="Deborah demonstrates" class="art" style="background-size:300% 200%;background-position:'+str((pose%3)*50)+'% '+str((pose//3)*100)+'%"></div>'
        elif art == 'bosses': s += '<div class="boss-art" role="img" aria-label="Neil, Brute, and Gordon the Warden"></div>'
        if chapter.get('rows'):s += '<table>'+''.join('<tr>'+''.join('<td>'+esc(t)+'</td>' for t in row)+'</tr>' for row in chapter['rows'])+'</table>'
        if chapter.get('steps'):s += '<ol>'+''.join('<li>'+esc(t)+'</li>' for t in chapter['steps'])+'</ol>'
        s += ''.join('<p>'+esc(t)+'</p>' for t in chapter.get('text',[]))
        for entry in chapter.get('entries',[]):
            s += '<section class="entry" id="'+esc(entry['id'])+'"><h3>'+esc(entry['name'])+'</h3><p class="requirement">'+esc(entry['requirement'])+'</p><p>'+esc(entry['text'])+'</p>'
            if entry.get('actors'):s += '<p class="actors">'+esc(entry['actors'])+'</p>'
            s += '</section>'
        if chapter.get('quote'):s += '<blockquote>“'+esc(chapter['quote'])+'”<br>— Deborah</blockquote>'
        s += '<div class="folio">THE LEGEND OF DEBORAH · '+str(len(pages)+1)+'</div></article>';pages.append(s)
    options = '<option value="0">Cover</option>'+''.join('<option value="'+str(i+1)+'">'+str(i+2)+' · '+esc(c['title'])+'</option>' for i,c in enumerate(book['chapters']))
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Legend of Deborah · Instruction Booklet</title><style>'+CSS+'.art{background-image:url('+uris['deborah']+')} .boss-art{width:100%;padding-bottom:66.666%;background:white url('+uris['bosses']+') center/contain no-repeat}</style></head><body><nav id="toolbar" aria-label="Manual navigation"><div class="line"><button id="prev">← Previous</button><select id="contents" aria-label="Contents">'+options+'</select><button id="next">Next →</button></div><div class="line"><input id="search" aria-label="Search manual" placeholder="Find a rule, enemy, or feat"><button id="find">Find next</button><button id="smaller" aria-label="Smaller text">A−</button><button id="larger" aria-label="Larger text">A+</button></div><div id="status" aria-live="polite"></div></nav><main id="reader" tabindex="0">'+''.join(pages)+'</main><script>'+JS+'</script></body></html>'


def pdf(book, destination):
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Flowable, KeepTogether, KeepInFrame
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.colors import HexColor
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from pypdf import PdfReader, PdfWriter
    fontdir=Path('/usr/share/fonts/truetype/dejavu')
    pdfmetrics.registerFont(TTFont('Manual',str(fontdir/'DejaVuSans.ttf')))
    pdfmetrics.registerFont(TTFont('ManualBold',str(fontdir/'DejaVuSans-Bold.ttf')))
    pdfmetrics.registerFontFamily('Manual',normal='Manual',bold='ManualBold',italic='Manual',boldItalic='ManualBold')
    W,H=297,378
    ink,blue,red=map(HexColor,('#202020','#1c4c85','#ce402e'))
    styles={
        'body':ParagraphStyle('body',fontName='Manual',fontSize=8,leading=10.1,spaceAfter=5,textColor=ink),
        'heading':ParagraphStyle('heading',fontName='ManualBold',fontSize=17,leading=18.5,spaceAfter=7,textColor=blue,keepWithNext=True),
        'sub':ParagraphStyle('sub',fontName='ManualBold',fontSize=10,leading=11.5,spaceBefore=7,spaceAfter=4,textColor=blue,keepWithNext=True),
        'small':ParagraphStyle('small',fontName='ManualBold',fontSize=7.1,leading=9,spaceAfter=5,textColor=red,keepWithNext=True),
        'quote':ParagraphStyle('quote',fontName='ManualBold',fontSize=8.3,leading=10.5,spaceBefore=5,spaceAfter=6,textColor=blue,borderColor=blue,borderWidth=1,borderPadding=6),
        'cell':ParagraphStyle('cell',fontName='Manual',fontSize=7.5,leading=10,textColor=ink)}
    def p(text,sty='body'):return Paragraph(esc(text),styles[sty])
    class Art(Flowable):
        def __init__(self,art,width,height):super().__init__();self.art=art;self.width=width;self.height=height
        def draw(self):
            c=self.canv
            if self.art.startswith('deborah:'):
                pose=int(self.art.split(':')[1]);size=self.height;x=(self.width-size)/2
                c.saveState();path=c.beginPath();path.rect(x,0,size,size);c.clipPath(path,stroke=0)
                c.drawImage(str(SOURCE/'art/deborah.jpg'),x-(pose%3)*size,-(1-pose//3)*size,width=size*3,height=size*2)
                c.restoreState()
            else:c.drawImage(str(SOURCE/'art'/(self.art+'.jpg')),0,0,width=self.width,height=self.height,preserveAspectRatio=True,anchor='c')
    def frame(c,d):
        c.setFillColor(HexColor('#f8d348') if d.page==1 else HexColor('#fffdf7'));c.rect(0,0,W,H,stroke=0,fill=1)
        c.setFillColor(red);c.rect(19,H-23,W-38,6,stroke=0,fill=1)
        c.setFont('ManualBold',5.8);c.setFillColor(blue);c.drawString(20,H-13,'THE LEGEND OF DEBORAH / INSTRUCTION BOOKLET')
        c.setStrokeColor(blue);c.line(20,24,W-20,24);c.setFont('ManualBold',6)
        c.drawString(20,13,'EXPANDED EDITION');c.drawRightString(W-20,13,str(d.page))
    story=[]
    story += [p('THE LEGEND\nOF DEBORAH'.replace('\n',' '),'heading'),p('RESCUE HER. AGAIN.','sub'),Art('cover',247,210),p(book['edition'],'small'),PageBreak()]
    story += [p('Chapter guide','heading'),p('Numbers match the in-game chapter selector. PDF bookmarks jump directly to the guide and reference chapters.')]
    for i,c in enumerate(book['chapters']):
        if c.get('group'):continue
        story.append(p(str(i+2).zfill(2)+'  '+c['title'],'cell'))
    story += [p('Then: 135 ordinary feats · 6 fallback feats · 9 class capstones · all equipment properties','small'),PageBreak()]
    for chapter in book['chapters']:
        chapter_start=len(story)
        story.append(p(chapter.get('group','HOW TO PLAY').upper(),'small'))
        if not chapter.get('entries'):story.append(p(chapter['title'],'heading'))
        if chapter.get('art'):
            story.extend([Art(chapter['art'],247,48 if chapter['art'].startswith('deborah') else 65),Spacer(1,5)])
        if chapter.get('rows'):
            data=[[p(t,'cell') for t in row] for row in chapter['rows']]
            t=Table(data,colWidths=[88,159],hAlign='LEFT')
            t.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('ROWBACKGROUNDS',(0,0),(-1,-1),[HexColor('#f5efdb'),HexColor('#fffdf7')]),('BOTTOMPADDING',(0,0),(-1,-1),5),('TOPPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,-1),.3,HexColor('#cec3a7'))]))
            story.extend([t,Spacer(1,8)])
        for i,text in enumerate(chapter.get('steps',[])):story.append(p(str(i+1)+'. '+text))
        story.extend(p(t) for t in chapter.get('text',[]))
        for e in chapter.get('entries',[]):
            story.extend([p(e['name'],'sub'),p(e['requirement'],'small'),p(e['text'])])
            if e.get('actors'):story.append(p(e['actors']))
        if chapter.get('quote'):
            story.append(Spacer(1,7))
            story.append(p('“'+chapter['quote']+'” — Deborah','quote'))
        if not chapter.get('group'):
            content=story[chapter_start:]; del story[chapter_start:]
            holder=KeepInFrame(235,290,content,mode='shrink')
            holder.manual_anchor=(chapter['id'],chapter['title'])
            story.extend([holder,PageBreak()])
        else:
            story[chapter_start].manual_anchor=(chapter['id'],chapter['title'])
            story.append(Spacer(1,8))
    story += [PageBreak()]
    story += [p('DEBORAH IS STILL WAITING.','heading'),Art('deborah:0',247,170),p('Press P → MANUAL anywhere the Player Menu is available. Press E at the staging book to return to the same reader.','quote')]
    destination=Path(destination);destination.parent.mkdir(parents=True,exist_ok=True)
    class BookDoc(SimpleDocTemplate):
        def afterFlowable(self,flowable):
            anchor=getattr(flowable,'manual_anchor',None)
            if anchor:
                self.canv.bookmarkPage(anchor[0]);self.canv.addOutlineEntry(anchor[1],anchor[0],level=0)
    doc=BookDoc(str(destination),pagesize=(W,H),leftMargin=25,rightMargin=25,topMargin=34,bottomMargin=34,title=book['title']+' — Instruction Booklet',author='The Legend of Deborah')
    doc.build(story,onFirstPage=frame,onLaterPages=frame)
    # Booklet signatures contain a multiple of four pages. Extra pages are notes.
    reader=PdfReader(str(destination));writer=PdfWriter();writer.append(reader)
    if len(reader.pages)%4:
        from reportlab.pdfgen import canvas
        import io
        buf=io.BytesIO();c=canvas.Canvas(buf,pagesize=(W,H))
        for _ in range((-len(reader.pages))%4):
            c.setFont('ManualBold',18);c.setFillColor(blue);c.drawString(25,H-48,'FIELD NOTES')
            c.setStrokeColor(HexColor('#dbd2ba'))
            for y in range(45,310,19):c.line(25,y,W-25,y)
            c.showPage()
        c.save();buf.seek(0);writer.append(PdfReader(buf))
    writer.add_metadata({'/Title':book['title']+' — Expanded Instruction Booklet','/Author':'The Legend of Deborah'})
    with destination.open('wb') as f:writer.write(f)
    print(f'PDF: {len(writer.pages)} pages, {destination}')


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--pdf');ap.add_argument('--check',action='store_true');args=ap.parse_args()
    book=chapters();content=make_html(book)
    digest=hashlib.sha256(content.encode()).hexdigest()
    outputs={SOURCE/'manual.html':content}
    # Bound each compressed client download source well below AddCSLuaFile limits.
    chunks=[content[i:i+48000] for i in range(0,len(content),48000)]
    for i,chunk in enumerate(chunks,1):outputs[TARGET/f'html_{i:02}.lua']='-- Generated by tools/build_manual.py; edit docs/manual/book.json.\nreturn [====['+chunk+']====]\n'
    outputs[TARGET/'manifest.lua']='-- Generated. Both entry points use these exact bytes.\nreturn {version="'+digest[:16]+'", chapters='+str(len(book['chapters'])+1)+', chunks='+str(len(chunks))+'}\n'
    for path,text in outputs.items():
        if args.check:
            assert path.exists() and path.read_text()==text, f'Stale generated manual: {path}'
        else:path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
    if not args.check:
        for path in TARGET.glob('html_*.lua'):
            if path not in outputs:path.unlink()
    if args.pdf:pdf(book,args.pdf)
    print(f'Manual: {len(book["chapters"])+1} chapters; {len(chunks)} client chunks; sha256 {digest}')


if __name__=='__main__':main()
