# Technical notes

The assignment DB applies the initiation cost and duration. Lua never deducts treasury, preventing double charges.

`CharacterTurnEnd` observes a newly started assignment and saves its due turn. `FactionTurnStart` heals when the due turn is reached. If the active assignment disappears before that due turn, `CharacterTurnEnd` clears the saved treatment as a recall/cancellation.

Automatic expiry may remove `active_assignment()` before `FactionTurnStart`; for this reason the saved due turn is authoritative on the completion turn.

The script uses the public 3K interfaces `active_assignment`, `assignment_record_key`, character CEO query management, and modify-character CEO management (`remove_ceos`, `add_ceo`).

