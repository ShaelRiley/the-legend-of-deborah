-- B20 authored tactical identities, independent of affinity, model and RPG class.
-- Load after ordinary encounter templates. Objectives, bosses, events and
-- summons deliberately have no ecology membership. This is selection data;
-- physical admission and encounter/entity budgets remain their own authorities.
local D=LOD.EncounterDirector
D.EcologyCatalog={
    common={patrol=true,rush=true,runner_ambush=true,firing_line=true,mixed_pressure=true,arena=true},
    themes={
        corruption={name="Corruption",templates={
            accumulator_detail=true,arccaster_zone=true,bigcrab_breath=true,
            bio_pressure=true,deadcrab_nest=true,flamer_pressure=true,
            gaoler_hold=true,lurker_ceiling=true,nodule_gas=true,
            silencer_screen=true,siphoner_pressure=true,
        }},
        crossfire={name="Crossfire",templates={
            beamsweeper_lane=true,bombardier_pressure=true,caromer_screen=true,
            conductor_pressure=true,forker_crossfire=true,fusilier_screen=true,
            incoming=true,reeler_chase=true,repulsor_screen=true,
            surveyor_detail=true,
        }},
        hunting={name="Hunting Grounds",templates={
            climber_wall=true,harrier_screen=true,listener_detail=true,
            outrider_detail=true,pincer_detail=true,razor_cover=true,
            reaper_detail=true,shy_pressure=true,surveillance=true,
            waylayer_cutoff=true,
        }},
        occupation={name="Occupation",templates={
            blitzer_firing_line=true,bulwark_line=true,censor_detail=true,
            halter_detail=true,interposer_detail=true,pacer_chase=true,
            pavise_advance=true,redliner_pressure=true,repriser_detail=true,
            sentry_flank=true,sniper_firing_line=true,
        }},
        quarantine={name="Quarantine",templates={
            censer_advance=true,cordon_screen=true,drubber_chase=true,
            fencer_screen=true,screenwright_detail=true,snarer_detail=true,
            towline_detail=true,trailmaker_chase=true,wirewright_chase=true,
        }},
        retinue={name="Funeral Retinue",templates={
            absolver_detail=true,afterburst_detail=true,cantor_charge=true,
            carrion_feast=true,exactor_pressure=true,lacemaker_detail=true,
            mourner_detail=true,relay_detail=true,stitcher_detail=true,
        }},
    },
    -- Families describe primary counterplay and may cross theme boundaries.
    -- Each ordinary identity has exactly one stable family, including companions.
    families={
        -- ambush
        deadcrab="ambush",listener="ambush",lurker="ambush",shy="ambush",
        watcher="ambush",
        -- area
        arccaster="area",beamsweeper="area",bigcrab="area",flamer="area",
        nodule="area",
        -- companion
        interposer="companion",lacemaker="companion",mourner="companion",relay="companion",
        -- control
        censor="control",exactor="control",gaoler="control",halter="control",
        pacer="control",repulsor="control",silencer="control",surveyor="control",
        -- line fire
        bioblaster="line_fire",blitzer="line_fire",seeker="line_fire",sentry="line_fire",
        sniper="line_fire",soldier="line_fire",
        -- melee
        drubber="melee",fencer="melee",reaper="melee",shambler="melee",
        -- position
        censer="position",conductor="position",screenwright="position",towline="position",
        trailmaker="position",
        -- projectile
        bombardier="projectile",caromer="projectile",forker="projectile",fusilier="projectile",
        reeler="projectile",
        -- pursuit
        climber="pursuit",harrier="pursuit",outrider="pursuit",pincer="pursuit",
        razor="pursuit",runner="pursuit",waylayer="pursuit",
        -- reaction
        pavise="reaction",redliner="reaction",repriser="reaction",
        -- remains
        afterburst="remains",carrion="remains",
        -- resource
        accumulator="resource",siphoner="resource",
        -- support
        absolver="support",bulwark="support",cantor="support",stitcher="support",
        -- trap
        cordon="trap",snarer="trap",wirewright="trap",
    }
}
