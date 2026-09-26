-- Run the shipped client card-layout functions with measured-text/Derma/net
-- adapters. This is layout/callback evidence, not native GMod visual acceptance.
LOD={CharacterSheet={},Audio={Play=function() end},UI={Colors={}}}
for _,key in ipairs({'paper','light','ink','red','blue','peach','gold','muted'}) do LOD.UI.Colors[key]={} end
hook={Add=function() end};concommand={Add=function() end};net={Receive=function() end}
surface={SetFont=function() end,GetTextSize=function(text) return #text*7,16 end}
Color=function(...) return {...} end
local sent,current={}
net.Start=function(name) current={name=name} end
net.WriteString=function(value) current.featId=value end
net.WriteUInt=function(value,bits) current.level=value;current.bits=bits end
net.SendToServer=function() sent[#sent+1]=current end
local all={}
vgui={Create=function(kind,parent)
    local panel={kind=kind,parent=parent,children={},enabled=true}
    if parent then parent.children[#parent.children+1]=panel end
    all[#all+1]=panel
    function panel:SetText(v) self.text=v end
    function panel:GetText() return self.text end
    function panel:SetFont(v) self.font=v end
    function panel:GetFont() return self.font end
    function panel:SetTextColor(v) self.color=v end
    function panel:SetWrap(v) self.wrap=v end
    function panel:SetWide(v) self.w=v end
    function panel:SetTall(v) self.h=v end
    function panel:SetSize(w,h) self.w=w;self.h=h end
    function panel:SetPos(x,y) self.x=x;self.y=y end
    function panel:SetTooltip(v) self.tooltip=v end
    function panel:SetEnabled(v) self.enabled=v end
    return panel
end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_character_sheet.lua')
local function upvalue(fn,wanted)
    for i=1,100 do
        local name,value=debug.getupvalue(fn,i)
        if not name then break end
        if name==wanted then return value end
    end
    error('Missing production upvalue '..wanted)
end
local render=upvalue(LOD.CharacterSheet.Open,'addFeatCards')
local cards=upvalue(render,'addDraftCards')
local checks=0
local function check(v,msg) checks=checks+1;assert(v,'SPOT11_UI: '..msg) end
local function draft(n,resolved)
    local d={earnedAtLevel=9,offerLimit=n==3 and 3 or 4,offers={},resolved=resolved}
    for i=1,n do
        d.offers[i]={featId='CARD_'..i,displayName='Offer '..i..' with a long wrapped title',
            eligibilityText='DEX 15 / requires a previous feat',
            effect=string.rep('A complete effect with its duration and limits. ',i+1),selected=resolved and i==n}
    end
    return d
end
for _,width in ipairs({240,360,588,620,948}) do
    for _,n in ipairs({1,2,3,4}) do
        all={};local parent={children={}}
        local d=draft(n,false)
        local height=render(parent,{featDraft=d},7,11,width)
        check(#parent.children==n,'all and only offered cards rendered')
        for i,a in ipairs(parent.children) do
            check(a.x>=7 and a.x+a.w<=7+width and a.w>0,'card horizontally bounded')
            check(a.y>=11 and a.y+a.h<=11+height,'scroll height includes full card')
            local footer=a.children[#a.children]
            check(footer.kind=='DButton' and footer.y+footer.h<=a.h,'select button accessible')
            local effect=a.children[#a.children-1]
            check(effect.y+effect.h<footer.y,'wrapped effect clears button')
            for j=i+1,#parent.children do
                local b=parent.children[j]
                check(a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y,'cards never overlap')
            end
        end
        if n==4 then
            local p=parent.children
            if width>=588 then check(p[1].y==p[2].y and p[3].y==p[4].y and p[3].y>p[1].y,'wide four-card hand uses two rows')
            else check(p[2].y>p[1].y and p[4].y>p[3].y,'narrow hand stacks and scrolls') end
            local button=p[4].children[#p[4].children]
            button:DoClick()
            local request=sent[#sent]
            check(request.name=='LOD_RPG_ChooseFeat' and request.featId=='CARD_4','fourth actual callback selects fourth ID')
            check(request.level==9 and request.bits==5 and button.enabled==false,'draft-level stale guard sent and button disabled')
        end
    end
end
for _,mode in ipairs({'resolved','readOnly'}) do
    local parent={children={}};all={}
    cards(parent,draft(4,mode=='resolved'),mode=='readOnly',0,0,620,'Choose',function() error('read-only chose') end)
    local selected=0
    for _,panel in ipairs(all) do
        check(panel.kind~='DButton','resolved/read-only hand has no clickable choices')
        if panel.text=='SELECTED' then selected=selected+1 end
    end
    check(selected==(mode=='resolved' and 1 or 0),'exactly one selected result rendered')
end
local parent={children={}}
check(cards(parent,draft(0,false),false,0,0,620,'Choose',function() end)==0 and #parent.children==0,'empty pool fabricates no UI card')
-- Same helper still lays out a fixed capstone trio in three columns when wide.
parent={children={}}
cards(parent,draft(3,false),false,0,0,948,'Choose capstone',function() end)
check(#parent.children==3 and parent.children[3].y==parent.children[1].y,'wide capstone trio unchanged')
print(string.format('SPOT11_DRAFT_UI_PASS: %d production layout/callback assertions; native visual acceptance remains open.',checks))
