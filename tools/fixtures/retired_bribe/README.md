# Retired Bribe test fixtures

These three modules are the exact historical Bribe implementation retained for
archival transaction/topology regression tests. They are not part of the shipped
gamemode, are never included by production init, and must not be re-enabled in the
current event catalog. Current quiz-generation tests prove Bribe is unavailable.

Legacy event presentation/barrier compatibility readers remain in production;
this move does not break old snapshot rendering or replace the shared barrier
owner. Historical source bytes and failed evidence remain in Git history.
