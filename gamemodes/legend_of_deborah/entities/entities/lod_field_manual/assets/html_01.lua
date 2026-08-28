return [========[
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Legend of Deborah — Instruction Booklet</title>
<style>
:root{
  --paper:#f4edda;
  --paper2:#fbf7e9;
  --ink:#20201d;
  --red:#aa3d32;
  --blue:#375b91;
  --peach:#edc9a2;
  --gold:#c79a39;
  --shadow:rgba(18,16,12,.38);
  --stage:#15171a;
}
*{box-sizing:border-box}
html,body{height:100%;margin:0}
body{
  background:
    radial-gradient(circle at 50% 25%,rgba(255,255,255,.06),transparent 34%),
    #111316;
  color:var(--ink);
  font-family:Georgia,"Times New Roman",serif;
  overflow:hidden;
}
button{font:inherit}
#manualApp{height:100%;display:flex;flex-direction:column}
.toolbar{
  display:flex;gap:.45rem;align-items:center;justify-content:center;
  min-height:48px;padding:7px 12px;background:rgba(12,13,15,.92);
  border-bottom:1px solid rgba(255,255,255,.12);color:#eee;
}
.toolbar button{
  border:1px solid rgba(255,255,255,.24);background:#25282d;color:#f5f2e8;
  padding:.45rem .7rem;border-radius:3px;cursor:pointer;
}
.toolbar button:hover,.toolbar button:focus{background:#343943;outline:2px solid #7ca1d8;outline-offset:1px}
.toolbar .spacer{flex:1}
.toolbar .folio{font:700 12px/1 Arial,sans-serif;letter-spacing:.08em;color:#d7d2c5}
.book-stage{
  flex:1;display:flex;align-items:center;justify-content:center;
  perspective:1800px;padding:20px 30px 28px;min-height:0;
}
.book{
  width:min(1180px,94vw);height:min(760px,calc(100vh - 96px));
  display:grid;grid-template-columns:1fr 1fr;
  transform-style:preserve-3d;filter:drop-shadow(0 20px 25px rgba(0,0,0,.48));
}
.book.turn-next{animation:turnNext .42s ease both}
.book.turn-prev{animation:turnPrev .42s ease both}
@keyframes turnNext{0%{transform:rotateY(0)}45%{transform:rotateY(-7deg) scale(.985)}100%{transform:rotateY(0)}}
@keyframes turnPrev{0%{transform:rotateY(0)}45%{transform:rotateY(7deg) scale(.985)}100%{transform:rotateY(0)}}
.page-slot{
  min-width:0;min-height:0;position:relative;overflow:hidden;
  background:
    linear-gradient(90deg,rgba(0,0,0,.025),transparent 8%,transparent 92%,rgba(0,0,0,.025)),
    repeating-linear-gradient(0deg,rgba(80,66,41,.018) 0,rgba(80,66,41,.018) 1px,transparent 1px,transparent 5px),
    var(--paper);
}
.page-slot.left{border-radius:7px 0 0 7px;box-shadow:inset -18px 0 22px -22px #000}
.page-slot.right{border-radius:0 7px 7px 0;box-shadow:inset 18px 0 22px -22px #000;border-left:1px solid rgba(70,60,40,.18)}
.source-page{display:none}
.page{
  height:100%;padding:42px 46px 50px;position:relative;overflow:hidden;
  background:transparent;
}
.page.cover,.page.back-cover{padding:0}
.page h1{
  margin:0 0 8px;font-family:"Arial Narrow","DejaVu Sans Condensed",Impact,sans-serif;
  font-stretch:condensed;font-size:clamp(35px,4.0vw,62px);line-height:.92;
  letter-spacing:-.035em;text-transform:uppercase;color:var(--red);
}
.page h2{
  margin:10px 0 8px;font:italic 700 clamp(17px,1.5vw,23px)/1.15 Georgia,serif;color:var(--blue);
}
.page h3{
  margin:14px 0 5px;font:800 15px/1.1 Arial,sans-serif;text-transform:uppercase;letter-spacing:.04em;color:var(--red);
}
.page p,.page li{font-size:clamp(14px,1.18vw,18px);line-height:1.35}
.page p{margin:.45em 0 .65em}
.page ul,.page ol{margin:.35em 0 .7em;padding-left:1.25em}
.rule{height:4px;background:var(--red);margin:0 0 16px}
.blue-rule{height:2px;background:var(--blue);margin:10px 0 13px}
.kicker{font:800 12px/1 Arial,sans-serif;letter-spacing:.15em;text-transform:uppercase;color:var(--blue);margin-bottom:8px}
.note{
  position:absolute;left:0;right:0;bottom:0;padding:10px 38px 11px;
  background:var(--peach);border-top:1px solid rgba(102,69,42,.24);
  font:700 13px/1.25 Arial,sans-serif;color:#3f352b;
}
.note strong{color:var(--red);letter-spacing:.04em}
.folio-num{
  position:absolute;bottom:12px;right:16px;font:700 10px/1 Arial,sans-serif;color:#776f63;
}
.note + .folio-num{bottom:9px}
.columns{display:grid;grid-template-columns:1fr 1fr;gap:20px}
.card-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:10px}
.card{
  border:1px solid rgba(70,60,40,.23);background:rgba(255,255,255,.25);padding:10px;
}
.card h3{margin-top:0}
.emblem{
  display:inline-grid;place-items:center;width:58px;height:58px;border:3px solid currentColor;
  font:900 28px/1 Arial,sans-serif;margin:3px 8px 3px 0;vertical-align:middle;
}
.red{color:#b13e35}.blue{color:#3c62a1}.yellow{color:#c39a22}
.triangle{clip-path:polygon(50% 0,100% 100%,0 100%);background:#b13e35;color:#fff;border:0}
.circle{border-radius:50%;background:#3c62a1;color:#fff;border:0}
.square{background:#d2ab31;color:#211;border:0}
.diagram{
  border:1px solid rgba(70,60,40,.22);background:rgba(255,255,255,.32);
  padding:12px;margin:10px 0;
}
.keycap{
  display:inline-block;min-width:28px;padding:3px 6px;margin:1px 2px;border:1px solid #706b60;
  border-bottom-width:3px;background:#f7f2df;border-radius:3px;
  font:800 12px/1.1 Arial,sans-serif;text-align:center;
}
.die{
  display:inline-grid;place-items:center;width:48px;height:48px;border:2px solid var(--blue);
  border-radius:9px;font:900 17px/1 Arial,sans-serif;color:var(--blue);background:#fffaf0;
}
.weapon-row{display:grid;grid-template-columns:1.2fr .65fr 2fr;gap:7px;align-items:center;padding:7px 0;border-bottom:1px solid rgba(70,60,40,.18)}
.weapon-row b{font-family:Arial,sans-serif}
.silhouette{
  height:105px;border:1px dashed #8b8171;display:grid;place-items:center;
  font:italic 700 16px Georgia,serif;color:#706758;background:rgba(60,55,48,.04);
}
.hand{
  font-family:"Comic Sans MS","Bradley Hand",cursive;color:#4b5d77;transform:rotate(-2deg);
  font-size:16px;font-weight:700;
}
.big-quote{
  font-size:clamp(24px,2.7vw,42px)!important;line-height:1.05!important;
  color:var(--blue);font-style:italic;margin-top:24px!important;
}
.contents button{
  display:block;width:100%;text-align:left;border:0;border-bottom:1px dotted #9d927f;
  background:transparent;padding:7px 2px;color:var(--ink);cursor:pointer;
  font:700 14px/1.15 Arial,sans-serif;
}
.contents button span{float:right;color:var(--blue)}
.contents button:hover,.contents button:focus{color:var(--red);outline:none;background:rgba(170,61,50,.05)}
.cover-art{
  width:100%;height:100%;position:relative;display:grid;place-items:center;text-align:center;
  background:
    radial-gradient(circle at 50% 42%,rgba(255,248,206,.27),transparent 27%),
    linear-gradient(145deg,#d5b146,#b78c2b 48%,#d1a63d);
  color:#2a2417;
}
.cover-art:before,.cover-art:after{
  content:"";position:absolute;inset:22px;border:2px solid rgba(51,41,20,.45);pointer-events:none;
}
.cover-art:after{inset:28px;border-width:1px}
.cover-title{font:900 clamp(42px,5vw,78px)/.9 "Arial Narrow","DejaVu Sans Condensed",Impact,sans-serif;letter-spacing:-.04em;text-transform:uppercase}
.cover-title small{display:block;font-size:.42em;letter-spacing:.09em;margin-bottom:8px}
.cover-sub{font:800 13px/1 Arial,sans-serif;letter-spacing:.18em;text-transform:uppercase;margin-top:18px}
.cover-seal{
  width:100px;height:100px;margin:26px auto 20px;border:4px double #3a2f18;border-radius:50%;
  display:grid;place-items:center;font:900 44px/1 Georgia,serif;
}
.back-message{font:900 clamp(32px,4vw,58px)/1 "Arial Narrow",Impact,sans-serif;text-transform:uppercase;max-width:75%}
.smallprint{position:absolute;bottom:48px;font:700 10px/1.3 Arial,sans-serif;letter-spacing:.07em;text-transform:uppercase;max-width:72%}
.reading{
  display:none;position:absolute;inset:48px 0 0;background:#f6f0df;overflow:auto;padding:35px max(30px,calc((100vw - 820px)/2)) 90px;z-index:10;
}
.reading.active{display:block}
.reading article{margin:0 auto 48px;max-width:820px;border-bottom:1px solid #c9bea9;padding-bottom:30px}
.reading h1{font-family:"Arial Narrow",Impact,sans-serif;color:var(--red);text-transform:uppercase}
.reading h2{color:var(--blue)}
.reading p,.reading li{font-size:20px;line-height:1.55}
.reading .note{position:static;margin-top:18px}
.reading .folio-num{display:none}
.reading .cover,.reading .back-cover{background:var(--paper);padding:30px}
.reading .cover-art{min-height:420px}
.nav-edge{
  position:absolute;top:55px;bottom:0;width:7vw;z-index:8;border:0;background:transparent;cursor:pointer;
}
.nav-edge.prev{left:0}.nav-edge.next{right:0}
.nav-edge:focus{outline:2px solid rgba(124,161,216,.8);outline-offset:-4px}
.legend-route{
  display:flex;flex-wrap:wrap;gap:5px;align-items:center;font:800 13px/1.2 Arial,sans-serif;
}
.legend-route span{padding:6px 7px;background:#eee4cc;border:1px solid #cbbda1}
.legend-route i{color:var(--red);font-style:normal}
.statline{
  display:grid;grid-template-columns:1fr auto;gap:8px;padding:6px 0;border-bottom:1px dotted #a79c88;
}
@media(max-width:820px){
  .book-stage{padding:12px}
  .book{grid-template-columns:1fr;width:min(650px,95vw)}
  .page-slot.left{display:none}
  .page-slot.right{border-radius:7px;border-left:0}
  .page{padding:32px 30px 48px}
  .toolbar .optional{display:none}
}
@media(prefers-reduced-motion:reduce){
  .book.turn-next,.book.turn-prev{animation:none!important}
}
@media print{
  body{overflow:visible;background:#fff}
  .toolbar,.book-stage,.nav-edge,.reading{display:none!important}
  #pageSource{display:block!important}
  .source-page{display:block!important;page-break-after:always;width:5.5in;height:8.5in;margin:0 auto;background:var(--paper)}
  .source-page .page{display:block;height:8.5in}
}
</style>
</head>
<body>
<div id="manualApp">
  <div class="toolbar" role="toolbar" aria-label="Manual controls">
    <button id="contentsBtn">Contents</button>
    <button id="readBtn">Reading Mode</button>
    <button id="soundBtn" class="optional">Sound: On</button>
    <button id="motionBtn" class="optional">Motion: On</button>
    <div class="spacer"></div>
    <div id="folio" class="folio" aria-live="polite">COVER</div>
    <div class="spacer"></div>
    <button id="closeBtn">Close Book</button>
  </div>

  <button class="nav-edge prev" id="prevEdge" aria-label="Previous pages"></button>
  <button class="nav-edge next" id="nextEdge" aria-label="Next pages"></button>

  <main class="book-stage" aria-label="The Legend of Deborah instruction booklet">
    <div class="book" id="book">
      <section class="page-slot left" id="leftPage" aria-label="Left page"></section>
      <section class="page-slot right" id="rightPage" aria-label="Right page"></section>
    </div>
  </main>

  <section class="reading" id="readingView" aria-label="Accessible reading mode"></section>

  <div id="pageSource" hidden>
    <article class="source-page" data-title="Cover">
      <div class="page cover">
        <div class="cover-art">
          <div>
            <div class="cover-title"><small>The Legend of</small>Deborah</div>
            <div class="cover-seal">D</div>
            <div class="cover-sub">Instruction Booklet</div>
            <div class="cover-sub">For 1–4 Expeditioners</div>
          </div>
          <div class="smallprint">Read before entering the labyrinth. Re-reading afterward is also permitted.</div>
        </div>
      </div>
    </article>

    <article class="source-page" data-title="Before Anything Else">
      <div class="page">
        <div class="kicker">A small warning</div>
        <h1>Before Anything Else</h1><div class="rule"></div>
        <p class="big-quote">This booklet will tell you how to survive. It will not tell you what is waiting for you.</p>
        <p>The labyrinth changes. Its rules are more dependable than its rooms.</p>
        <p>Learn the rules. Notice the signs. Take the weapon the Hermit gives you.</p>
        
        <div class="note"><strong>DEBORAH'S NOTE:</strong> If you came here to rescue me, thank you. If you came here by mistake, you may as well help.</div>
        <div class="folio-num">1</div>
      </div>
    </article>

    <article class="source-page" data-title="Contents">
      <div class="page contents">
        <div class="kicker">What is in this book</div>
        <h1>Contents</h1><div class="rule"
]========]
