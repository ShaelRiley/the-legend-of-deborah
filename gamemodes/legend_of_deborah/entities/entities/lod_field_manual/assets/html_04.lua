return [========[
N BAD IDEAS</div>
        <div class="folio-num">21</div>
      </div>
    </article>

    <article class="source-page" data-title="Back Cover">
      <div class="page back-cover">
        <div class="cover-art">
          <div class="back-message">You know enough.<br><br>The rest is down there.</div>
          <div class="smallprint">Close the book. Take the weapon. Enter the labyrinth. Rescue Deborah.</div>
        </div>
      </div>
    </article>
  </div>
</div>

<script>
(function(){
  "use strict";
  const source = [...document.querySelectorAll(".source-page")];
  const book = document.getElementById("book");
  const left = document.getElementById("leftPage");
  const right = document.getElementById("rightPage");
  const folio = document.getElementById("folio");
  const reading = document.getElementById("readingView");
  let anchor = 0;
  let soundOn = true;
  let motionOn = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let readingOn = false;
  let busy = false;

  function nativeCall(name, ...args){
    try{
      if(window.lod && typeof window.lod[name] === "function") window.lod[name](...args);
    }catch(e){}
  }

  function compact(){
    return window.matchMedia("(max-width:820px)").matches;
  }

  function clonePage(index){
    if(index < 0 || index >= source.length) return document.createElement("div");
    const node = source[index].querySelector(".page").cloneNode(true);
    node.querySelectorAll("[data-jump]").forEach(btn => {
      btn.addEventListener("click",()=>jump(parseInt(btn.dataset.jump,10)));
    });
    return node;
  }

  function render(){
    if(compact()){
      left.innerHTML = "";
      right.innerHTML = "";
      right.appendChild(clonePage(anchor));
      folio.textContent = source[anchor]?.dataset.title || "";
      return;
    }
    if(anchor % 2 !== 0) anchor -= 1;
    left.innerHTML = "";
    right.innerHTML = "";
    left.appendChild(clonePage(anchor));
    if(anchor + 1 < source.length) right.appendChild(clonePage(anchor+1));
    folio.textContent = (source[anchor]?.dataset.title || "") + (source[anchor+1] ? "  ·  " + source[anchor+1].dataset.title : "");
  }

  function maxAnchor(){
    if(compact()) return source.length - 1;
    return Math.max(0, source.length - (source.length % 2 ? 1 : 2));
  }

  function turn(direction){
    if(readingOn || busy) return;
    const step = compact() ? 1 : 2;
    const next = Math.max(0, Math.min(maxAnchor(), anchor + direction*step));
    if(next === anchor) return;
    busy = true;
    if(soundOn) nativeCall("pageTurn", next, direction);
    const klass = direction > 0 ? "turn-next" : "turn-prev";
    if(motionOn){
      book.classList.add(klass);
      setTimeout(()=>{ anchor=next; render(); }, 185);
      setTimeout(()=>{ book.classList.remove(klass); busy=false; }, 430);
    }else{
      anchor=next; render(); busy=false;
    }
  }

  function jump(index){
    if(readingOn) toggleReading(false);
    anchor = Math.max(0, Math.min(source.length-1, index));
    if(!compact() && anchor % 2 !== 0) anchor -= 1;
    render();
    if(soundOn) nativeCall("pageTurn", anchor, 1);
  }

  function buildReading(){
    reading.innerHTML = "";
    source.forEach((article)=>{
      const out = document.createElement("article");
      out.appendChild(article.querySelector(".page").cloneNode(true));
      out.querySelectorAll("[data-jump]").forEach(btn=>btn.remove());
      reading.appendChild(out);
    });
  }

  function toggleReading(force){
    readingOn = typeof force === "boolean" ? force : !readingOn;
    reading.classList.toggle("active",readingOn);
    document.getElementById("readBtn").textContent = readingOn ? "Book View" : "Reading Mode";
    if(readingOn){ buildReading(); reading.scrollTop=0; }
  }

  document.getElementById("prevEdge").addEventListener("click",()=>turn(-1));
  document.getElementById("nextEdge").addEventListener("click",()=>turn(1));
  document.getElementById("contentsBtn").addEventListener("click",()=>jump(2));
  document.getElementById("readBtn").addEventListener("click",()=>toggleReading());
  document.getElementById("soundBtn").addEventListener("click",(e)=>{
    soundOn=!soundOn;e.currentTarget.textContent="Sound: "+(soundOn?"On":"Off");
  });
  document.getElementById("motionBtn").addEventListener("click",(e)=>{
    motionOn=!motionOn;e.currentTarget.textContent="Motion: "+(motionOn?"On":"Off");
  });
  document.getElementById("closeBtn").addEventListener("click",()=>nativeCall("closeBook"));

  window.addEventListener("resize",()=>{ if(!readingOn) render(); });
  window.addEventListener("keydown",(e)=>{
    const k=e.key.toLowerCase();
    if(e.key==="Escape"){ e.preventDefault(); nativeCall("closeBook"); return; }
    if(readingOn) return;
    if(e.key==="ArrowRight" || k==="d"){ e.preventDefault();turn(1); }
    if(e.key==="ArrowLeft" || k==="a"){ e.preventDefault();turn(-1); }
    if(k==="c"){ e.preventDefault();jump(2); }
    if(k==="r"){ e.preventDefault();toggleReading(); }
  });
  render();
  nativeCall("ready",source.length);
})();
</script>
</body>
</html>

]========]
