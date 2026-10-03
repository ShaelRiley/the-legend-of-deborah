-- Authored campaign identity, independent of encounter choreography and tuning.
LOD.BossRegistry=LOD.BossRegistry or {}
local R=LOD.BossRegistry
R.Order={'warden','chonker','felon','melf','ollie','crystal_bepis','daryl','sofa','marion','button','ray','cornette','moshi','chuck','rank_and_file','flightmeister','conan','joilette','little_mooky','warden'}
R.Names={warden='Gordon the Warden',chonker='Chonker the Honker',felon='Felon the Melon',melf='Melf the Yourself',ollie='Ollie the Trolly',crystal_bepis='Crystal Bepis',daryl='Daryl the Barrel',sofa='Sofa King Dangerous',marion='Marion the Carbarian',button='Button for Punishment',ray='Ray D. Aitor',cornette="Cornette, Who's Drills Hurt",moshi='Moshi the Washy',chuck='Chuck Chuck Bo Buck',rank_and_file='Rank and File',flightmeister='The Flightmeister',conan='Conan the Cone',joilette='Joilette the Toilet',little_mooky='Little Mooky',jane_propane='Jane the Propane'}
R.Modules={'chonker','felon','melf','ollie','crystal_bepis','daryl','sofa','marion','button','ray','cornette','moshi','chuck','rank_and_file','flightmeister','conan','joilette','little_mooky'}
R.Primary={};for _,id in ipairs(R.Order) do R.Primary[id]=true end
function R:ForLevel(level)
    -- This revision does not author an endless-mode selection policy.
    -- Returning nil preserves the preexisting endless Gordon path unchanged.
    return self.Order[math.floor(tonumber(level) or 1)]
end
function R:Modular(level) local id=self:ForLevel(level);return id and id~='warden' and id or nil end
function R:Name(level) local id=self:ForLevel(level);return self.Names[id or 'warden'] end
function R:GordonClones(level)
    if level==1 then return 0 end;if level==20 then return 4 end
    if self:Modular(level) then return 0 end
    return math.min(4,math.max(0,math.floor((tonumber(level) or 1)/4)))
end
function R:GordonTurrets(level)
    if level==1 then return 0 end;if level==20 then return 4 end
    if self:Modular(level) then return 0 end
    return math.min(4,math.max(0,math.floor((tonumber(level) or 1)/5)))
end
