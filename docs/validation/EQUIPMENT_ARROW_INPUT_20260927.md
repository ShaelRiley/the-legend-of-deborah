# Arrow-input equipment attack repair — September 27, 2026

Author report: equipment with arrow-input special attacks produces no attack.
This is a separate input-transport repair accompanying Heavy Plumber contact,
not a new scheduled SPOT-18 or a restart of the deferred roadmap.

## Authority and correction

Live GDD 00 -> 01 -> 90 equipment controls and 03 innate attack contracts were
read September 27. Physical keyboard arrows and existing keyboard mirrors feed
one server-authoritative recipe stream. One edge is one token; holding a key
is not repetition. UI/chat/throwable exclusion and owned-item/cost/cooldown/status
checks remain unchanged.

The old receiver enforced a 0.025-second interval **between packet receipt
times**. Separate honest key presses delivered together therefore lost the
second/third token before recipe recognition. Replace that gate with one bounded
eight-token burst (the existing maximum recipe length), refilling at the original
40 tokens/second. Resets consume credits too and cannot refill the limiter.
Overload clears a partial recipe instead of splicing the next accepted key into
it. A reset of an inactive actor does not create a gameplay session.

The decoder now accepts a small 3..16-bit envelope while reading only the original
three-bit token. This is bounded framing compatibility, not a claim that a
particular native build was observed adding padding. Short/oversized messages and
reserved tokens cancel partial input without spending Magic; only values 1..4
can reach the existing dispatcher. The payload still cannot choose attacks,
positions, targets, prices or cooldowns. No direct client attack authority.

## Finite validation

`test_equipment_transport.lua`: actual receiver, batched and bounded padded
messages, one debit/cooldown, malformed lengths/reserved tokens, reset-spam limit,
refill, insufficient Magic, unequipped source, Soldier/dead/throwable exclusion.
The baseline loses a same-tick three-UP recipe; the repaired receiver executes it.

`test_special_move_end_to_end.lua`: actual client Think keyboard edge adapter and
mirrors -> queued network boundary -> actual receiver -> actual paired-glove
ownership/recipe/cost dispatcher -> actual Ember Fist projectile Initialize,
Think/impact and shared damage, plus actual Cinder Rise area damage. Holding a
key adds no repeat, UI reset cancels the prefix, and unequipping before delivery
cannot retain the attack. Baseline receiver fails the Ember Fist assertion.
Native transport and Source physics remain boundary doubles, not engine proof.

The full retained faction/stair selected gate plus focused equipment neighbors is
`tools/test_equipment_activation_gate.py`. All-source before/after hashes, exact
suite count and Lua syntax count belong to the external delivery receipt. No
full campaign matrix or native acceptance is claimed.

## Native observation

On the updated deployed Hero, run `lod_fighting_streets_testkit`, close the
console/menus, and tap/release LEFT DOWN RIGHT for Ember Fist, then RIGHT DOWN
RIGHT for Cinder Rise near a visible enemy in the same square. Expect the actual
projectile/strike and one 12/18-base-Magic debit, subject to existing cost modifiers.
Holding a potion/bomb disables these Magic techniques. Inspect other owned moves
with their displayed recipes; `lod_thunder_hat_testkit` provides UP DOWN UP where
safe floor is available. Retain cooldown/no-Magic, menu interruption and
locked-geometry behavior. Record exact build, observation, console_latest.txt and
rpg_summary_latest.txt. No Workshop/VPS action is included.
