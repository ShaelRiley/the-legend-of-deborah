# Retained performance integration evidence

This bundle supports a focused integration of retained partial improvements, not completion of the 40 FPS objective. The sibling JSON links the original measurements and identifies correctness dependencies separately. Research history/settings/profilers/rejected experiments are excluded.

Exact-main tests: 325/334 effective after three missing-dependency reruns. The immutable integration matrix is326/336 at42d40b23; one newly introduced source-manifest fixture omission was corrected atb33ab811 and its affected gate passed, giving327/336 effective composite coverage. All nine remaining failures match main by test name and error/BLOCKER signature. The original receipts/failures are preserved; this is not a claim that a second complete matrix ran. GitHub PR checks provide final-head verification.

Actual Deck smoke checks validate native source/HUD/render state,327851 history checks with original data/providers restored, fixed six HUD textures/cleanup, nine stair physical cases/448 steps with restoration, and normal forward movement. Both displays stayed on. Stair tests use disposable actors with own AI paused and32×72 hulls; they do not prove every authored boss AI/hull or full gameplay. No FPS acceptance is claimed.

The initial dark visual reference comparison failed the historical8/20 bound. A fixed retained/integration two-VM control reproduced that first-reference issue on both sources. All cached outputs equal historical accepted PNGs; repeated references converge and pass the unchanged gate. Bright/background/fade checks pass. See the complete cold/repeat records; no tolerance or production rendering change was made. The initial postprocessor's mistaken6/1 criterion is separately corrected, not hidden.

Full raw headless logs remain at `/home/deck/deborah-recovery/main-integration-baseline-20261026/matrix` and `/home/deck/deborah-recovery/retained-integration-20261026/matrix`; receipts and all failed-suite logs are included here. Native raw console/helper backups remain local; relevant proof receipts, source identities and PNGs are included. `SHA256SUMS` covers published files.

Update after the authorized main merge:

```bash
cd /home/deck/Downloads/the-legend-of-deborah
git fetch origin main
git switch main
git pull --ff-only origin main
bash tools/install_dev.sh
```

Fully quit Garry's Mod before changing the installed checkout, then restart it. Workshop/VPS deployment is outside this task. Sustained40FPS remains unmet and the optimization goal remains paused.
