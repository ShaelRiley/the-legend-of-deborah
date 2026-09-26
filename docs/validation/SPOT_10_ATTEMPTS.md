# SPOT-10 local attempt provenance
Early focused source hashes were not captured. Log SHA256 values below identify the retained raw logs, not a reconstructed source snapshot.
- Attempt 1: FAIL (fixture; preserved); [SPOT_10_FOCUSED_01.txt](SPOT_10_FOCUSED_01.txt); SHA256 `2adf966d8b9954257be4df7b86bfe03979f244925fe88a7790bf635a8a1c7b89`.
- Attempt 2: FAIL (fixture; preserved); [SPOT_10_FOCUSED_02.txt](SPOT_10_FOCUSED_02.txt); SHA256 `075e459308d3ad6e6e176a811bc13873f1a44dd433a4435937bb712c45c5bd53`.
- Attempt 3: PASS 129 assertions; [SPOT_10_FOCUSED_03.txt](SPOT_10_FOCUSED_03.txt); SHA256 `4323254c872cfab2fe6504085782fd5f99b72d36648950ba38ad22ab3a95c7a4`.

First aggregate passed 64/64 and 741 Lua syntax checks without source mutation. Final frozen/independent receipts are external to avoid self-reference.
