# Precognition

Precognition teaches and reinforces Vim navigation by showing where Motions would move from the current cursor position before the user moves.

## Language

**Hint**:
A visual cue that shows where a Motion would move from the current cursor position.
_Avoid_: Mark, cue

**Inline Hint**:
A Hint rendered within the buffer text area to show the column component of a Destination on the current line.
_Avoid_: Virtual line mark, inline mark

**Gutter Hint**:
A Hint rendered in the sign column to show the line component of a Destination.
_Avoid_: Sign, gutter mark

**Motion**:
A Vim navigation command that moves the cursor from one buffer position to another.
_Avoid_: Keybind, command

**Counted Motion**:
A Motion modified by a numeric count, such as `2w`, whose Destination is the result of applying the Motion count times.
_Avoid_: Count hint, repeated hint

**Motion Count**:
The leading numeric prefix used to calculate a Counted Motion Destination.
_Avoid_: Operator count, command count

**Destination**:
The buffer position where Vim would land after a Motion, even when that is the current position.
_Avoid_: Location, place, mark

**Peek**:
A temporary display of Hints until the next cursor movement, insert mode entry, or buffer exit.
_Avoid_: Preview, flash

**Screen Assertion**:
A test assertion that verifies rendered Hints as they appear in a Neovim screen, rather than only inspecting internal data structures.
_Avoid_: Visual confirmation, screenshot test

**Hint Priority**:
The precedence used to choose which Hint appears when multiple Hints share the same Destination.
_Avoid_: Weight, rank

**Excluded Buffer**:
A buffer where Precognition intentionally shows no Hints.
_Avoid_: Disabled filetype, blacklisted buffer

## Relationships

- A **Hint** represents one **Motion** from the current cursor position.
- A **Counted Motion** is a **Motion** and has one **Destination** from the current cursor position.
- Precognition currently supports **Counted Motion** Hints for horizontal word Motions: `w`, `e`, `b`, `W`, `E`, and `B`.
- Counted **Gutter Hints** and counted vertical Motions are intentionally out of scope until designed separately.
- A **Counted Motion** with no reachable **Destination** should not display a **Hint**.
- While the user enters a numeric count prefix, Precognition should update supported horizontal word Motion **Hints** to their counted **Destinations** before the final Motion key is pressed.
- Count prefixes above `100` suppress **Counted Motion** Hints.
- Count parsing for **Counted Motion** Hints uses the leading numeric count prefix only.
- A **Motion Count** is the leading numeric prefix used to calculate a **Counted Motion** **Destination**.
- **Counted Motion** Hints are part of default Hint behavior and do not have a separate disable option.
- Operator-pending counts, such as `2d3w`, are intentionally out of scope until operator-pending behavior is designed separately.
- The current count prefix should be treated as input to **Counted Motion** Hint calculation, not as a rendering concern.
- **Motion Count** comes from typed input, not from command-display text, so visual selection reporting is not interpreted as a count.
- In visual mode, a **Hint** previews where a **Motion** would move the active end of the selection, not where the whole selection would move.
- Visual mode uses the same **Motion Count** behavior as normal mode for supported horizontal word Motions.
- A **Hint** appears at the **Destination** for its **Motion**.
- An **Inline Hint** is a **Hint** for the column component of a **Destination** on the current line.
- A **Gutter Hint** is a **Hint** for the line component of a **Destination**.
- A **Peek** temporarily displays the currently available **Hints**.
- A **Screen Assertion** can verify whether **Hints** appear at the expected on-screen positions.
- End-to-end tests that assert what a user sees should prefer **Screen Assertions** over inspecting rendering internals.
- **Screen Assertions** run across supported CI operating systems to verify rendered **Hint** consistency.
- A **Hint Priority** resolves conflicts between **Hints** with the same **Destination**.
- A **Hint** with priority zero is suppressed.
- An **Excluded Buffer** suppresses all **Hints**.
- Entering insert mode suppresses all **Hints**.
- Paragraph Motion **Gutter Hints** use Destinations visible in the current window; file-boundary Motion **Gutter Hints** use file-boundary Destinations even when those lines are off-screen.

## Boundaries

- Domain language describes **Hints**, **Motions**, **Destinations**, **Peeks**, **Hint Priority**, and **Excluded Buffers**; Neovim mechanisms such as extmarks, virtual lines, signs, namespaces, and adapters are implementation language.

## Example dialogue

> **Dev:** "Should this **Motion** display a **Hint** when it has no **Destination**?"
> **Domain expert:** "No, a **Hint** only appears when the **Motion** has a **Destination** from the current cursor position."

> **Dev:** "If `gg` is used on the first line, does it still have a **Destination**?"
> **Domain expert:** "Yes - its **Destination** is the first line, even though the cursor would not visibly move."

## Flagged ambiguities

- "mark" was used for the visual cue shown by Precognition, but Vim already has marks with a different meaning - resolved: use **Hint** for the visual cue.
- "motion" was used to mean both the Vim command and the resulting position - resolved: use **Motion** for the command and **Destination** for the position.
- "count" was ambiguous because it could be treated as a separate Hint behavior - resolved: use **Counted Motion** for a Motion modified by a numeric count.
- Operator-pending counts were ambiguous because multiplying numeric groups can produce misleading standalone Motion **Hints** - resolved: **Counted Motion** Hints use only the leading numeric count prefix for now.
- "virtual line" describes a Neovim rendering mechanism, not the user-facing concept - resolved: use **Inline Hint** for the user-facing Hint.
- Insert-mode behavior was ambiguous because Inline Hints and Gutter Hints could be treated differently - resolved: entering insert mode suppresses all **Hints**.
- "visual confirmation" was ambiguous because it could mean manual review or automated testing - resolved: use **Screen Assertion** for automated tests of rendered Hints.
