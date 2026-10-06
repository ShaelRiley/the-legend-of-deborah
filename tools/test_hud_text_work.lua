-- Actual unchanged parent/candidate UI and feed, with stock native-call doubles.
-- Raster submissions and bounded work counts, never native FPS certification.
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
local cases = {
    {{text='Rhea',role='identity'},{text=' as ',role='prose'},
     {text='Deborah',role='character'},{text=' dealt ',role='prose'},
     {text='1d6 + 1d6! [6 > 2]',role='dice'},{text=' = 14',role='total'},
     {text=' DAMAGE → Soldier.',role='damage'}},
    {{text='AVATAR café Deborah → 龍: ',role='identity'},
     {text=string.rep('AV',80),role='prose'},{text=' 1d12! > 12 = 24',role='continuation'}},
    {{text='   ',role='prose'},{text='10',role='dice'},{text='   ',role='prose'},
     {text='DODGE',role='clear'}},
    {{text='',role='prose'}},
    {{text='Health regeneration: 1d4 [3] = 3',role='resource'}}
}
local function copy(v)
    if type(v)~='table' then return v end
    local out={};for k,item in pairs(v) do out[k]=copy(item) end;return out
end
local function equal(a,b,label)
    if type(a)~='table' or type(b)~='table' then assert(a==b,label);return end
    for k,v in pairs(a) do equal(v,b[k],label..'/'..tostring(k)) end
    for k in pairs(b) do assert(a[k]~=nil,label..'/extra/'..tostring(k)) end
end
local function record(spans,serial,created)
    local texts={};for _,span in ipairs(spans) do texts[#texts+1]=span.text end
    return {text=table.concat(texts),segments=copy(spans),family='routine',
        serial=serial or 1,created=created or 100}
end
local function run(uiPath,feedPath,candidate)
    local clock,screenWidth,screenHeight=100,1280,800
    local font,x,y,r,g,b,a,metricScale='?',0,0,0,0,0,255,1
    local trace,acks,measurements,fontSelections,colors={}, {},0,0,0
    local hooks={}
    LOD={CombatRollFeed={entries={}}}
    TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT=0,1,2
    TEXT_ALIGN_TOP,TEXT_ALIGN_BOTTOM=3,4
    function Color(cr,cg,cb,ca) colors=colors+1;return {r=cr,g=cg,b=cb,a=ca or 255} end
    function CurTime() return clock end
    function ScrW() return screenWidth end;function ScrH() return screenHeight end
    function math.Clamp(n,lo,hi) return math.max(lo,math.min(hi,n)) end
    hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
    concommand={Add=function() end}
    surface={CreateFont=function() end,
        SetFont=function(f) font=f;fontSelections=fontSelections+1 end,
        GetTextSize=function(text)
            measurements=measurements+1
            local width=0;for _,cp in utf8.codes(text) do width=width+(cp>127 and 9 or 7) end
            -- Whole-string kerning deliberately differs from token sums.
            local _,pairs=text:gsub('AV','');width=width-pairs*2
            return width*metricScale*(font=='ChatFont' and 1 or 1.1),17*metricScale
        end,
        SetTextPos=function(nx,ny) x,y=nx,ny end,
        SetTextColor=function(cr,cg,cb,ca) r,g,b,a=cr,cg,cb,ca or 255 end,
        DrawText=function(text) trace[#trace+1]={font,text,x,y,r,g,b,a} end,
        SetDrawColor=function() end,
        DrawCircle=function(...) trace[#trace+1]={'circle',...} end,
        DrawLine=function(...) trace[#trace+1]={'line',...} end}
    draw={}
    -- Primary Facepunch draw.lua contract: selection, measurement, alignment,
    -- ceil coordinates and native submission. One-pixel outline includes 0,0.
    draw.SimpleText=function(text,f,px,py,c,ax,ay)
        text=tostring(text);surface.SetFont(f or 'DermaDefault')
        local w,h=surface.GetTextSize(text)
        if ax==TEXT_ALIGN_CENTER then px=px-w/2 elseif ax==TEXT_ALIGN_RIGHT then px=px-w end
        if ay==TEXT_ALIGN_CENTER then py=py-h/2 elseif ay==TEXT_ALIGN_BOTTOM then py=py-h end
        surface.SetTextPos(math.ceil(px),math.ceil(py))
        surface.SetTextColor(c.r,c.g,c.b,c.a);surface.DrawText(text)
        return w,h
    end
    draw.SimpleTextOutlined=function(text,f,px,py,c,ax,ay,outline,oc)
        local step=math.max(1,outline*2/3)
        for dx=-outline,outline,step do for dy=-outline,outline,step do
            draw.SimpleText(text,f,px+dx,py+dy,oc,ax,ay)
        end end
        return draw.SimpleText(text,f,px,py,c,ax,ay)
    end
    dofile(root..'sh_die_logger.lua');dofile(uiPath);dofile(feedPath)
    local UI,Feed=LOD.UI,LOD.CombatRollFeed
    Feed.AckFeedback=function(_,entry,stage,retained) acks[#acks+1]={entry.serial,stage,retained} end
    local function reset() trace,acks,measurements,fontSelections,colors={}, {},0,0,0 end
    local function invalidate(event)
        for _,fn in pairs(hooks[event] or {}) do fn() end
    end
    local results={}
    for case,spans in ipairs(cases) do
        for _,width in ipairs({70,180.5,600}) do
            for _,hud in ipairs({true,false}) do
                local entry=record(spans);local lines,widths=Feed:Layout(entry,width,hud)
                local formatted={}
                for i,line in ipairs(lines) do
                    formatted[i]={};for j,span in ipairs(line) do formatted[i][j]={span.text,span.role} end
                end
                for _,alpha in ipairs({0,0.5,107.75,255}) do
                    reset();Feed:DrawLines(lines,-3.4,14.2,alpha,1,#lines,hud)
                    results[#results+1]={formatted=copy(formatted),widths=copy(widths),trace=copy(trace)}
                end
                reset();Feed:DrawLines(lines,1.1,-9.8,255,math.min(2,#lines),#lines,hud)
                results[#results+1]={trace=copy(trace)}
            end
        end
    end
    -- Every alignment keeps the same native trace; non-left/top remains stock.
    for _,ax in ipairs({TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT}) do
        for _,ay in ipairs({TEXT_ALIGN_TOP,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM}) do
            reset();UI:HUDText('AV café →','ChatFont',-0.4,17.8,Color(120,180,255,127.5),ax,ay)
            results[#results+1]={trace=copy(trace)}
        end
    end
    reset();UI:HUDText('default',nil,0,0,nil)
    results[#results+1]={trace=copy(trace)}
    for _,position in ipairs({0,1e-17,-1e-17,0.9999999999999999,1.0000000000000002,
        -1.0000000000000002,9007199254740992}) do
        reset();UI:HUDText(1234,'ChatFont',position,position,Color(10,20,30,0))
        results[#results+1]={trace=copy(trace)}
    end
    -- Actual HUD tail: ordering, truncation hint, ACK attempts, expiry and fade.
    for _,t in ipairs({100,108.99,109,109.4,110.4,110.4001,112}) do
        for _,sw in ipairs({641,1280,1920}) do
            reset();clock=t;screenWidth=sw;screenHeight=801
            Feed.entries={}
            for i=1,10 do Feed.entries[i]=record(cases[(i-1)%#cases+1],i,99+i*0.1) end
            hooks.HUDPaint.LOD_CombatRollFeed()
            local serials={};for _,entry in ipairs(Feed.entries) do serials[#serials+1]=entry.serial end
            results[#results+1]={trace=copy(trace),acks=copy(acks),entries=serials}
        end
    end
    for kind=0,2 do
        for _,age in ipairs({0,0.19,0.519,0.52}) do
            clock=100+age;Feed.entries={};Feed.diceExplosion={created=100,kind=kind,count=3,depth=2}
            reset();hooks.HUDPaint.LOD_CombatRollFeed()
            results[#results+1]={trace=copy(trace),expired=Feed.diceExplosion==nil}
        end
    end
    -- Warm the actual layout, then count work over 600 identical rendered tails.
    local lines=Feed:Layout(record(cases[1]),600,true)
    Feed:DrawLines(lines,400,400,255,1,#lines,true);reset()
    for _=1,600 do Feed:DrawLines(lines,400,400,255,1,#lines,true) end
    local work={measurements=measurements,font_selections=fontSelections,colors=colors,draws=#trace}
    results[#results+1]={trace=copy(trace)}
    local spanCount=0;for _,line in ipairs(lines) do spanCount=spanCount+#line end
    if candidate then
        assert(work.measurements==0 and work.font_selections==spanCount*600,'steady native work retained')
        assert(work.draws==spanCount*600*10,'outline/foreground submissions changed')
        local entry=record(cases[1]);local first=Feed:Layout(entry,600,true)
        assert(Feed:Layout(entry,600,true)==first,'steady layout must be reused')
        metricScale=1.25;invalidate('OnScreenSizeChanged')
        local resized=Feed:Layout(entry,600,true);assert(resized~=first,'screen metrics not invalidated')
        Feed:DrawLines(resized,0,0,255,1,#resized,true);reset()
        Feed:DrawLines(resized,0,0,255,1,#resized,true);assert(measurements==0)
        metricScale=1.5;invalidate('OnReloaded');reset()
        -- Open history panels may retain an older lines reference through reload.
        Feed:DrawLines(resized,0,0,255,1,#resized,true);assert(measurements>0,'old lines metrics survived reload')
        assert(Feed:Layout(entry,600,true)~=resized,'layout survived reload')
        local changed=Feed:Layout(entry,600,true);entry.text='DODGE';entry.segments=nil
        assert(Feed:Layout(entry,600,true)~=changed,'changed record text survived')
        changed=Feed:Layout(entry,600,true);entry.segments={{text='DODGE',role='clear'}}
        assert(Feed:Layout(entry,600,true)~=changed,'replacement semantic spans survived')
        local fontChanged=Feed:Layout(entry,600,false)
        assert(entry.layoutFont=='LOD_CombatRoll' and fontChanged~=changed,'HUD/history font changed')
        reset();Feed:DrawLines(fontChanged,0,0,255,1,#fontChanged,false)
        assert(measurements==2,'first history draw must measure native draw plus advance')
        reset();fontChanged[1][1].text='AV';Feed:DrawLines(fontChanged,0,0,255,1,1,false)
        assert(measurements==2,'mutated drawn span retained stale advance')
        reset();local original=surface.DrawText;surface.DrawText=nil
        local fallbackCalls=0;local helper=draw.SimpleTextOutlined
        draw.SimpleTextOutlined=function() fallbackCalls=fallbackCalls+1 end
        UI:HUDText('fallback','ChatFont',1,1,nil);assert(fallbackCalls==1,'partial native API lost stock fallback')
        draw.SimpleTextOutlined=helper;surface.DrawText=original
        for i=1,1200 do
            local e=record(cases[1]);local l=Feed:Layout(e,600,true);Feed:DrawLines(l,0,0,255,1,1,true)
        end
        assert(Feed.entries[1]==nil,'drawing created retained gameplay entries')
        assert(not Feed.textWidths and not Feed.metricCache,'unbounded global string cache introduced')
    else
        assert(work.measurements==spanCount*600*11,'parent baseline no longer matches stock drawing contract')
    end
    return results,work
end
local before,beforeWork=run('tools/fixtures/hud_text_parent_ui.lua','tools/fixtures/hud_text_parent_semantics.lua',false)
local after,afterWork=run(root..'cl_ui_theme.lua',root..'cl_combat_roll_feed_semantics.lua',true)
equal(before,after,'parent/candidate raster trace')
assert(beforeWork.draws==afterWork.draws and beforeWork.font_selections>afterWork.font_selections)
print(string.format('HUD_TEXT_WORK_PASS traces=%d steady_frames=600 measurements=%d->%d font_selections=%d->%d colors=%d->%d native_draws=%d->%d; exact parent calls; refresh/screen/text/font invalidation; bounded layout ownership; not native FPS',
    #before,beforeWork.measurements,afterWork.measurements,beforeWork.font_selections,afterWork.font_selections,
    beforeWork.colors,afterWork.colors,beforeWork.draws,afterWork.draws))
