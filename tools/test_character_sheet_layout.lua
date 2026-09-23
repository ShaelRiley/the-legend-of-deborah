-- Production snapshots and complete Character Sheet; only Source/VGUI boundaries doubled.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local CPS,Run,Catalog=LOD.CharacterProgressionSystem,fixture.Run,LOD.RPG.IdentityCatalog
local p=fixture.actor('sheet-reader')
Run.State.RosterSeed=1729
p.ps.progressionState=nil
local character=LOD.Config.Models.Characters[1]
p.ps.model,p.ps.characterName,p.ps.lives=character.model,character.name,3
p.LODProgressionState=CPS:InitializeHero(Run,p.ps,character)
assert(CPS:CommitClass(p,'wizard'))
local offered=CPS:BuildClientSnapshot(p)
assert(offered and #offered.featDraft.offers==3)
for _,feat in ipairs(offered.featDraft.offers) do
    assert(feat.effect==CPS:_FindFeat(feat.featId).effectParams.description)
end
assert(CPS:CommitFeat(p,offered.featDraft.offers[1].featId,1))
assert(CPS:AdvanceHeroToLevel(p,20))
local snapshot=CPS:BuildClientSnapshot(p)
assert(snapshot.ownedFeats[1].effect==CPS:_FindFeat(snapshot.ownedFeats[1].featId).effectParams.description)
assert(snapshot.capstoneDraft and #snapshot.capstoneDraft.offers==3)
for _,feat in ipairs(snapshot.capstoneDraft.offers) do
    assert(feat.effect==Catalog.ClassCapstones.wizard[feat.featId].effectParams.description)
end
print('SHEET_SNAPSHOT_TEXT_PASS')

local nodes,receivers,hooks,requests,pendingTimers={},{},{},{},{}
local panel={};panel.__index=panel
local create
function panel:SetPos(x,y) self.x,self.y=x,y end
function panel:SetSize(w,h) self.w,self.h=w,h end
function panel:SetWide(w) self.w=w end
function panel:SetTall(h) self.h=h end
function panel:GetWide() return self.w end
function panel:GetTall() return self.h end
function panel:SetText(t) self.text=t end
function panel:GetText() return self.text end
function panel:SetFont(f) self.font=f end
function panel:GetFont() return self.font end
function panel:SetWrap(b) self.wrap=b end
function panel:SetTooltip(t) self.tooltip=t end
function panel:SetEnabled(b) self.enabled=b end
function panel:IsEnabled() return self.enabled~=false end
function panel:IsHovered() return false end
function panel:Remove()
    self.valid=false
    for _,child in ipairs(self.children) do child:Remove() end
end
function panel:GetCanvas()
    if not self.canvas then self.canvas=create('DPanel',self);self.canvas.w=self.w-18 end
    return self.canvas
end
function panel:GetVBar()
    if not self.bar then self.bar={scroll=0,GetScroll=function(b) return b.scroll end,
        SetScroll=function(b,n) b.scroll=n end} end
    return self.bar
end
for _,name in ipairs({'SetTextColor','SetContentAlignment','Center','SetTitle','ShowCloseButton',
    'SetDraggable','MakePopup','InvalidateLayout'}) do panel[name]=function() end end
create=function(kind,parent)
    local node=setmetatable({valid=true,kind=kind,parent=parent,children={},x=0,y=0,w=100,h=100},panel)
    nodes[#nodes+1]=node
    if parent then parent.children[#parent.children+1]=node end
    return node
end
vgui={Create=create}
IsValid=function(v) return type(v)=='table' and v.valid==true end
local sw,sh=1280,800
ScrW=function() return sw end;ScrH=function() return sh end
RealTime=function() return 100 end
local fonts,currentFont={},nil
surface={CreateFont=function(name,data) fonts[name]=data end,SetFont=function(font) currentFont=font end,
    GetTextSize=function(text)
        local size=(fonts[currentFont] or {}).size or 14
        return (utf8.len(text) or #text)*size*.56,size
    end}
net.Receive=function(name,fn) receivers[name]=fn end
local request
net.Start=function(name) request={name=name} end
net.WriteString=function(s) request[#request+1]=s end
net.WriteUInt=function(n,bits) request[#request+1]=n;request.bits=bits end
net.SendToServer=function() requests[#requests+1]=request end
hook.Add=function(_,id,fn) hooks[id]=fn end
concommand={Add=function() end}
timer.Simple=function(_,fn) pendingTimers[#pendingTimers+1]=fn end
LOD.Audio={Play=function() end}
LOD.CharacterPortrait={Create=function(_,parent) local n=create('Portrait',parent);n.Paint=function() end;return n end}
LOD.Wallet=nil -- Sibling page implementation is outside this fixture.
LOD.Equipment.MenuKey=nil
LOD.Spellbook=nil
input={}
dofile(root..'cl_ui_theme.lua')
dofile(root..'cl_character_sheet.lua')
local Sheet=LOD.CharacterSheet
local function flushTimers()
    local work=pendingTimers;pendingTimers={}
    for _,fn in ipairs(work) do fn() end
end
local function open(snap)
    Sheet.Snapshot=snap;nodes={};Sheet:Open(false);flushTimers()
end
local function buttons(text)
    local out={}
    for _,node in ipairs(nodes) do
        if node.valid and node.kind=='DButton' and node.text==text then out[#out+1]=node end
    end
    return out
end
local function nodeWithText(text,parent)
    for _,node in ipairs(nodes) do
        if node.valid and node.kind=='DLabel' and node.text==text and (not parent or node.parent==parent) then return node end
    end
end
local function within(node,parent)
    assert(node.w>0 and node.h>0,'Nonpositive text or control area')
    assert(node.x>=0 and node.x+node.w<=parent.w,'Horizontal overflow: '..tostring(node.text))
    assert(node.y>=0 and node.y+node.h<=parent.h,'Vertical overflow: '..tostring(node.text))
end
local function separated(a,b)
    return a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y
end
local function verifyDraft(draft,action)
    local cards={}
    -- Different canonical feats may share a display name (e.g. Spellbreaker).
    -- Production builds controls in offer order; name-only lookup selected the
    -- last namesake and compared the wrong canonical effect under pairs order.
    local choices=buttons(action)
    assert(#choices==#draft.offers,'Draft choice count differs from stored offers')
    for index,feat in ipairs(draft.offers) do
        local card=choices[index].parent
        local title=nodeWithText(feat.displayName,card)
        assert(title,'Full feat title missing from the correct draft')
        cards[#cards+1]=card
        within(card,card.parent)
        local effect=assert(nodeWithText(feat.effect,card),'Canonical effect missing or abbreviated')
        assert(title.wrap and effect.wrap,'Card text must wrap')
        for i,a in ipairs(card.children) do
            within(a,card)
            for j=i+1,#card.children do assert(separated(a,card.children[j]),'Card contents overlap') end
        end
        for _,button in ipairs(card.children) do
            if button.kind=='DButton' then
                surface.SetFont(button.font)
                assert(surface.GetTextSize(button.text)<=button.w,'Choice button caption is clipped')
                assert(button.text==action and button.tooltip=='Choose '..feat.displayName)
            end
        end
    end
    for i,a in ipairs(cards) do for j=i+1,#cards do assert(separated(a,cards[j]),'Draft cards overlap') end end
    local first=cards[1]
    if first then
        local lastBottom=0
        for _,card in ipairs(cards) do lastBottom=math.max(lastBottom,card.y+card.h) end
        for _,node in ipairs(first.parent.children) do
            if node.kind=='DLabel' and node.text and node.text:find('Locked draft seed',1,true) then
                if action=='CHOOSE FEAT' then assert(node.y>=lastBottom,'Draft overlaps following content') end
            end
        end
    end
    return cards
end

-- Render every registered description, including the longest ordinary/capstone text,
-- without changing eligibility: synthetic stored offers here exercise presentation only.
local entries={}
for _,def in pairs(Catalog.OrdinaryFeats) do entries[#entries+1]=def end
for _,class in pairs(Catalog.ClassCapstones) do for _,def in pairs(class) do entries[#entries+1]=def end end
for _,def in pairs(Catalog.FallbackFeats) do entries[#entries+1]=def end
local function dto(def)
    return {featId=def.featId,displayName=def.displayName,effect=def.effectParams.description,
        eligibilityText=def.eligibilityText}
end
-- Reproduce the former intermittent failure deterministically using two real
-- same-name feats with distinct effect text, independently asserted per card.
local namesakes
for _,a in ipairs(entries) do
    for _,b in ipairs(entries) do
        if a.featId~=b.featId and a.displayName==b.displayName
            and a.effectParams.description~=b.effectParams.description then namesakes={dto(a),dto(b)};break end
    end
    if namesakes then break end
end
assert(namesakes,'Same-name canonical feat regression fixture missing')
local duplicateNames=table.Copy(snapshot)
duplicateNames.featDraft.offers=namesakes
open(duplicateNames)
verifyDraft(duplicateNames.featDraft,'CHOOSE FEAT')
local resolutions={{640,480},{800,600},{980,720},{1024,768},{1280,800},{1920,1080}}
local seenOne,seenTwo,seenThree=false,false,false
for _,resolution in ipairs(resolutions) do
    sw,sh=resolution[1],resolution[2]
    for start=1,#entries,3 do
        local snap=table.Copy(snapshot)
        snap.featDraft.offers={}
        for i=start,math.min(start+2,#entries) do snap.featDraft.offers[#snap.featDraft.offers+1]=dto(entries[i]) end
        open(snap)
        local cards=verifyDraft(snap.featDraft,'CHOOSE FEAT')
        verifyDraft(snap.capstoneDraft,'CHOOSE CAPSTONE')
        if #cards>=2 then
            seenOne=seenOne or cards[2].y>cards[1].y
            seenTwo=seenTwo or cards[2].y==cards[1].y
            seenThree=seenThree or (#cards==3 and cards[3].y==cards[1].y)
        end
        for _,node in ipairs(Sheet.Frame.children) do
            if node.kind=='DLabel' and node.font=='LOD_SheetTitle' then
                surface.SetFont(node.font)
                assert(surface.GetTextSize(node.text)<=node.w,'Sheet title clipped at this viewport')
            end
        end
        local canvas=Sheet.Scroll:GetCanvas()
        for i,a in ipairs(canvas.children) do
            if a.kind~='Portrait' then within(a,canvas) end
            for j=i+1,#canvas.children do assert(separated(a,canvas.children[j]),'Sheet sections overlap') end
        end
    end
end
assert(seenOne and seenTwo and seenThree,'One, two and three-column draft layouts must be exercised')

-- Actual server snapshot -> choice control -> unchanged request contract.
sw,sh=1280,800;open(snapshot)
for i,button in ipairs(buttons('CHOOSE FEAT')) do
    local count=#requests;button:DoClick()
    local sent=requests[#requests]
    assert(#requests==count+1 and sent.name=='LOD_RPG_ChooseFeat')
    assert(sent[1]==snapshot.featDraft.offers[i].featId and sent[2]==snapshot.featDraft.earnedAtLevel and sent.bits==5)
    assert(not button:IsEnabled(),'Choice must disable while awaiting server')
end
for i,button in ipairs(buttons('CHOOSE CAPSTONE')) do
    button:DoClick();local sent=requests[#requests]
    assert(sent.name=='LOD_RPG_ChooseCapstone' and sent[1]==snapshot.capstoneDraft.offers[i].featId and sent[2]==nil)
end
local readOnly=table.Copy(snapshot);readOnly.readOnly=true
open(readOnly)
assert(#buttons('CHOOSE FEAT')==0 and #buttons('CHOOSE CAPSTONE')==0,'Read-only actor can choose a feat')
local resolved=table.Copy(snapshot)
resolved.featDraft.resolved=true;resolved.featDraft.offers[2].selected=true
resolved.capstoneDraft.resolved=true;resolved.capstoneDraft.offers[1].selected=true
open(resolved)
assert(#buttons('CHOOSE FEAT')==0 and #buttons('CHOOSE CAPSTONE')==0)
assert(nodeWithText('SELECTED') and nodeWithText('NOT SELECTED'))

-- Refresh/resize preserve the existing hand and scroll, issue no reroll requests,
-- and stale layout callbacks cannot restore into a newer character/window.
open(snapshot);Sheet.Scroll:GetVBar():SetScroll(275)
local before=#requests;net.ReadTable=function() return table.Copy(snapshot) end
receivers.LOD_RPG_Snapshot();flushTimers()
assert(Sheet.Scroll:GetVBar():GetScroll()==275 and #requests==before)
sw,sh=800,600;hooks.LOD_CharacterSheetResize();flushTimers()
assert(Sheet.Scroll:GetVBar():GetScroll()==275 and #requests==before)
verifyDraft(Sheet.Snapshot.featDraft,'CHOOSE FEAT')
local fresh=table.Copy(snapshot);fresh.portraitCacheKey='fresh-hero'
Sheet:Open(false);Sheet.Snapshot=fresh;Sheet:Open(false);flushTimers()
assert(Sheet.Scroll:GetVBar():GetScroll()==0,'Old Hero scroll leaked to a new identity')
Sheet:Open(false);Sheet:Close();flushTimers()
assert(Sheet.Frame==nil and Sheet.Scroll==nil)
print('CHARACTER_SHEET_LAYOUT_PASS: canonical snapshot text; '..#entries..' descriptions at six resolutions; bounded nonoverlapping cards/sections; exact choices; read-only/resolved states; refresh/resize/identity scroll lifecycle')
