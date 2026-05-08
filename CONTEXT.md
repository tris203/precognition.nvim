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

**Destination**:
The buffer position where Vim would land after a Motion, even when that is the current position.
_Avoid_: Location, place, mark

**Peek**:
A temporary display of Hints until the next cursor movement, insert mode entry, or buffer exit.
_Avoid_: Preview, flash

**Hint Priority**:
The precedence used to choose which Hint appears when multiple Hints share the same Destination.
_Avoid_: Weight, rank

**Excluded Buffer**:
A buffer where Precognition intentionally shows no Hints.
_Avoid_: Disabled filetype, blacklisted buffer

## Relationships

- A **Hint** represents one **Motion** from the current cursor position.
- A **Hint** appears at the **Destination** for its **Motion**.
- An **Inline Hint** is a **Hint** for the column component of a **Destination** on the current line.
- A **Gutter Hint** is a **Hint** for the line component of a **Destination**.
- A **Peek** temporarily displays the currently available **Hints**.
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
- "virtual line" describes a Neovim rendering mechanism, not the user-facing concept - resolved: use **Inline Hint** for the user-facing Hint.
- Insert-mode behavior was ambiguous because Inline Hints and Gutter Hints could be treated differently - resolved: entering insert mode suppresses all **Hints**.
