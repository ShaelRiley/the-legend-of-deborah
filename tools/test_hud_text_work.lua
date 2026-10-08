-- Actual frozen original/production UI and feed, with stock native-call doubles.
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
    local trace,acks,measurements,fontSelections,colors,ceilings={}, {},0,0,0,0
    local nativeCeil=math.ceil
    math.ceil=function(value) ceilings=ceilings+1;return nativeCeil(value) end
    local hooks={}
    LOD={CombatRollFeed={entries={}}}
    TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT=0,1,2
    TEXT_ALIGN_TOP,TEXT_ALIGN_BOTTOM=3,4
    function Color(cr,cg,cb,ca)
        colors=colors+1;return {r=math.min(tonumber(cr),255),g=math.min(tonumber(cg),255),
            b=math.min(tonumber(cb),255),a=math.min(tonumber(ca or 255),255)}
    end
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
    local function reset() trace,acks,measurements,fontSelections,colors,ceilings={}, {},0,0,0,0 end
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
                for _,alpha in ipairs({-12,0,0.5,107.75,255,300,'127.5'}) do
                    reset();Feed:DrawLines(lines,-3.4,14.2,alpha,1,#lines,hud)
                    results[#results+1]={formatted=copy(formatted),widths=copy(widths),trace=copy(trace)}
                end
                reset();Feed:DrawLines(lines,1.1,-9.8,255,math.min(2,#lines),#lines,hud)
                results[#results+1]={trace=copy(trace)}
            end
        end
    end
    -- Every stock alignment keeps the same native glyph trace.
    for _,ax in ipairs({TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT}) do
        for _,ay in ipairs({TEXT_ALIGN_TOP,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM}) do
            reset();UI:HUDText('AV café →','ChatFont',-0.4,17.8,Color(120,180,255,127.5),ax,ay)
            results[#results+1]={trace=copy(trace)}
        end
    end
    reset();UI:HUDText('default',nil,0,0,nil)
    results[#results+1]={trace=copy(trace)}
    for _,position in ipairs({0,1e-17,-1e-17,0.9999999999999999,1.0000000000000002,
        -1.0000000000000002,9007199254740992,-9007199254740992}) do
        reset();UI:HUDText(1234,'ChatFont',position,position,Color(10,20,30,0))
        results[#results+1]={trace=copy(trace)}
    end
    -- Stock adds each outline offset before subtracting alignment dimensions.
    -- Reordering those operations changes pixels at IEEE rounding boundaries.
    -- Dimensions remain live even when a caller owns the coordinate cache.
    local alignedCache={}
    for _,ax in ipairs({TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER,TEXT_ALIGN_RIGHT}) do
        for _,ay in ipairs({TEXT_ALIGN_TOP,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM}) do
            for _,position in ipairs({0,1e-17,-1e-17,0.9999999999999999,1.0000000000000002,
                -1.0000000000000002,9007199254740992,-9007199254740992}) do
                for _,scale in ipairs({0,1,1.25}) do
                    metricScale=scale
                    for _,owned in ipairs({false,alignedCache}) do
                        reset();surface.SetFont('unrelated')
                        UI:HUDText('AV café →','LOD_HUD_Small',position,position,
                            Color(120,180,255,127.5),ax,ay,owned or nil)
                        results[#results+1]={trace=copy(trace)}
                    end
                end
            end
        end
    end
    metricScale=1
    -- Non-string conversions may have callbacks. Keep their stock per-glyph
    -- conversion order instead of borrowing a value across those callbacks.
    local custom=setmetatable({count=0},{__tostring=function(self)
        self.count=self.count+1;return 'conversion '..self.count end})
    reset();assert(UI:HUDText(custom,'ChatFont',3.4,5.6,Color(10,20,30,80),
        TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)==nil)
    assert(custom.count==10,'aligned custom conversion no longer uses stock helper')
    results[#results+1]={trace=copy(trace)}
    for _,alpha in ipairs({-12,0,500}) do
        reset();UI:HUDText('alpha',nil,3.4,5.6,{r=10,g=20,b=30,a=alpha},
            TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
        results[#results+1]={trace=copy(trace)}
    end
    -- The owned path rounds the original floating-point sums, even after moves
    -- and font changes. An unrelated paint may change the selected surface font.
    local owned={}
    for _,position in ipairs({1e-17,0.9999999999999999,-1.0000000000000002,
        9007199254740992,400.25,400.25}) do
        for _,f in ipairs({'ChatFont','LOD_CombatRoll'}) do
            reset();surface.SetFont('unrelated');UI:HUDText('AV café →',f,position,position,
                Color(120,180,255,107.75),nil,nil,owned)
            results[#results+1]={trace=copy(trace)}
        end
    end
    local moving=Feed:Layout(record(cases[1]),600,true)
    for _,p in ipairs({{400.25,400.75,1},{400.25,400.75,1},{-1e-17,0.9999999999999999,1},
        {9007199254740992,9007199254740992,1},{12.75,-9.5,math.min(2,#moving)}}) do
        reset();surface.SetFont('unrelated')
        Feed:DrawLines(moving,p[1],p[2],107.75,p[3],#moving,true)
        results[#results+1]={trace=copy(trace)}
    end
    -- Reused colors follow live roles/palettes and alpha without tinting them.
    local paletteEntry=record(cases[1]);local paletteLines=Feed:Layout(paletteEntry,600,true)
    for change=1,4 do
        local first=paletteLines[1][1]
        if change==2 then first.role='damage';first.text='AV'
        elseif change==3 then UI.HUDRoles.damage=Color(91,92,93,94)
        elseif change==4 then
            UI.HUDRoles.damage.r=300;UI.HUDRoles.damage.g='98.5';UI.HUDRoles.damage.b=-12
        end
        reset();Feed:DrawLines(paletteLines,1.5,2.5,change==1 and 0 or 107.75,1,#paletteLines,true)
        results[#results+1]={trace=copy(trace)}
        assert(UI.HUDRoles.damage.a==(change>=3 and 94 or 255),'drawing mutated palette alpha')
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
    -- Caption and right/bottom HUD labels retain every native glyph while
    -- eliminating duplicate selection/measurement and outline Color creation.
    local alignedColor=Color(120,180,255,107.75)
    reset()
    for _=1,600 do
        assert(UI:HUDText('Jane "Steel" Doe','LOD_HUD_Small',500.5,400.25,alignedColor,
            TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)==nil)
        assert(UI:HUDText('10 / 20','DermaDefault',800.75,600.5,alignedColor,
            TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)==nil)
    end
    local alignedWork={measurements=measurements,font_selections=fontSelections,colors=colors,
        ceilings=ceilings,draws=#trace}
    results[#results+1]={trace=copy(trace)}
    -- Warm the actual layout, then count work over 600 identical rendered tails.
    local lines=Feed:Layout(record(cases[1]),600,true)
    Feed:DrawLines(lines,400,400,255,1,#lines,true);reset()
    for _=1,600 do Feed:DrawLines(lines,400,400,255,1,#lines,true) end
    local work={measurements=measurements,font_selections=fontSelections,colors=colors,
        ceilings=ceilings,draws=#trace}
    results[#results+1]={trace=copy(trace)}
    local spanCount=0;for _,line in ipairs(lines) do spanCount=spanCount+#line end
    if candidate==true then
        assert(work.measurements==0 and work.font_selections==600,'steady native font work retained')
        assert(work.colors==0 and work.ceilings==0,'steady allocation/position work retained')
        assert(work.draws==spanCount*600*10,'outline/foreground submissions changed')
        assert(alignedWork.measurements==1200 and alignedWork.font_selections==1200
            and alignedWork.colors==0,'aligned HUD repeats native font/metric/allocation work')
        assert(alignedWork.draws==12000 and alignedWork.ceilings==24000,'aligned glyph submissions or exact rounding changed')
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
        local metric=surface.GetTextSize;surface.GetTextSize=nil
        fallbackCalls=0;draw.SimpleTextOutlined=function() fallbackCalls=fallbackCalls+1 end
        UI:HUDText('fallback','ChatFont',1,1,nil,TEXT_ALIGN_CENTER)
        UI:HUDText('unknown','ChatFont',1,1,nil,99,98)
        assert(fallbackCalls==2,'partial metric API/unknown alignment lost stock fallback')
        draw.SimpleTextOutlined=helper;surface.GetTextSize=metric
        local released=setmetatable({},{__mode='k'})
        for i=1,1200 do
            local e=record(cases[1]);local l=Feed:Layout(e,600,true);Feed:DrawLines(l,0,0,255,1,1,true)
            released[l]=true;released[l[1][1]]=true
        end
        collectgarbage('collect');assert(next(released)==nil,'retired layout/span caches remain owned')
        assert(Feed.entries[1]==nil,'drawing created retained gameplay entries')
        assert(not Feed.textWidths and not Feed.metricCache,'unbounded global string cache introduced')
    elseif candidate==false then
        assert(work.measurements==spanCount*600*11,'parent baseline no longer matches stock drawing contract')
    end
    math.ceil=nativeCeil
    return results,work,alignedWork
end
local before,beforeWork,beforeAligned=run('tools/fixtures/hud_text_parent_ui.lua','tools/fixtures/hud_text_parent_semantics.lua',false)
local probe=arg and arg[1]=='--probe'
local external=probe or arg and arg[1]=='--gate'
local after,afterWork,afterAligned=run(external and arg[2] or root..'cl_ui_theme.lua',
    external and arg[3] or root..'cl_combat_roll_feed_semantics.lua',probe and 'probe' or true)
equal(before,after,'parent/candidate raster trace')
assert(beforeWork.draws==afterWork.draws and beforeWork.font_selections>afterWork.font_selections)
if probe and arg[4] then
    local function canonical(v)
        if type(v)~='table' then return type(v)..':'..string.format('%q',tostring(v)) end
        local keys={};for k in pairs(v) do keys[#keys+1]=k end
        table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
        local values={};for _,k in ipairs(keys) do values[#values+1]=canonical(k)..'='..canonical(v[k]) end
        return '{'..table.concat(values,',')..'}'
    end
    local out=assert(io.open(arg[4],'w'));out:write(canonical(after));out:close()
end
print(string.format('HUD_TEXT_WORK_PASS traces=%d steady_frames=600 measurements=%d->%d font_selections=%d->%d colors=%d->%d ceilings=%d->%d native_draws=%d->%d; exact parent calls; refresh/screen/text/font/position/palette invalidation; bounded layout ownership; not native FPS',
    #before,beforeWork.measurements,afterWork.measurements,beforeWork.font_selections,afterWork.font_selections,
    beforeWork.colors,afterWork.colors,beforeWork.ceilings,afterWork.ceilings,beforeWork.draws,afterWork.draws))
print(string.format('HUD_ALIGNED_WORK_PASS labels=1200 measurements=%d->%d font_selections=%d->%d colors=%d->%d ceilings=%d->%d native_draws=%d->%d; live metrics, exact aligned rounding, custom conversion/partial API fallback; not native FPS',
    beforeAligned.measurements,afterAligned.measurements,beforeAligned.font_selections,afterAligned.font_selections,
    beforeAligned.colors,afterAligned.colors,beforeAligned.ceilings,afterAligned.ceilings,beforeAligned.draws,afterAligned.draws))
