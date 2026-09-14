# Development workflow

Effective after Shael's 2026-09-14 approval and promotion of
`87920e5ba3b27d46ff096f5a85cd41030a77f964` to `main`.

- **Main:** canonical development and accepted implementation baseline.
- **Astra / Work:** primary implementation and senior-engineering environment.
- **Sol:** complementary architecture, review and planning; selected simpler,
  repetitive or otherwise bounded implementation where useful.
- **Antigravity:** retired as a development worker.
- **hybrid/antigravity:** retired as an active workflow; retained as published
  historical evidence. Do not resume packet issuance or ongoing branch work.
- **Shael:** design authority and human runtime acceptance owner.

## Working loop

Start from verified remote main and a clean checkout; use an isolated task branch
when needed. Follow AGENTS.md and targeted live-GDD navigation. Implement through
canonical authorities, run the integrated gate and relevant focused regressions,
and preserve coherent work in verified commits. Give Shael an exact candidate SHA
for changes requiring Source acceptance. Do not equate green static tests with
runtime acceptance or carry approval across materially changed runtime code.
Never force-push or rewrite published history. One writer owns each working tree.

Main promotion, public-server deployment and Workshop publication are separate
operations; obtain the corresponding user authorization rather than treating a
main merge as deployment permission.

Fully quit Garry's Mod before switching the installed checkout or installing:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
```

Use [test logging](TEST_LOGGING.md) for evidence collection. Preserve historical
handoffs and failed evidence; old Antigravity protocol/bundles are archival and
have no authority to restart the retired workflow.
