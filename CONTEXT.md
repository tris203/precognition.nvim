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

**Pending Command Prefix**:
The typed input that has begun a Vim command but has not yet completed it, such as a count prefix or a text-object prefix.
_Avoid_: Partial command, key buffer

**Text Object Hint**:
A Hint shown for a Vim text object after the user enters a text-object prefix, such as `vi`, `di`, `ci`, `yi`, `va`, `da`, `ca`, or `ya`.
_Avoid_: Inside jump hint, inside command hint

**Spatial Text Object Hint**:
A Text Object Hint anchored to one or more visible buffer characters to preview a text object's visible boundaries.
_Avoid_: Positional text-object hint

**Range Preview**:
A highlighted buffer range showing what a text object command would affect if completed with the hinted key.
_Avoid_: Selection preview, background hint

**Availability Text Object Hint**:
A Text Object Hint that indicates a text object is valid from the current cursor context without claiming a precise buffer position.
_Avoid_: Non-positional text-object hint, text-object menu item

**Text Object Source**:
A source of text-object candidates that can be shown as Text Object Hints.
_Avoid_: Text object motion

**Precognition Adapter**:
An extension point that may provide Motion behavior and Text Object Hint behavior.
_Avoid_: Treating text objects as cursor destinations

**Destination**:
The buffer position where Vim would land after a Motion, even when that is the current position.
_Avoid_: Location, place, mark

**Target Character Hint**:
An Inline Hint that previews the first same-line occurrence of a unique character reachable by an `f` or `F` Motion from either side of the cursor.
_Avoid_: Word jump hint, eyeliner mark

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
- A **Pending Command Prefix** is broader than a **Motion Count**; **Motion Count** was the first supported prefix behavior, and **Text Object Hints** add text-object prefix behavior.
- A **Text Object Hint** is different from a **Motion** Hint because it previews an available text object after a pending text-object prefix rather than a cursor **Destination**.
- While a text-object **Pending Command Prefix** is active, **Text Object Hints** replace normal **Motion** Hints rather than appearing alongside them.
- Once an operator or text-object **Pending Command Prefix** is active, normal **Motion** Hints remain suppressed until that prefix is completed or cancelled.
- **Text Object Hints** should support both inside text-object prefixes, such as `vi`, and around text-object prefixes, such as `va`.
- Inside and around prefixes use the same **Text Object Hint** candidates, but each candidate's meaning follows the active prefix.
- Built-in Vim text objects are the default **Text Object Hint** candidates; additional text objects may be exposed by a **Text Object Source**.
- **Text Object Sources** are conceptually separate from Motion sources because text objects are not **Motions** and do not have cursor **Destinations**.
- A **Precognition Adapter** may provide both Motion behavior and **Text Object Hint** behavior.
- Existing Motion registration is the current integration path for both Motion behavior and **Text Object Hint** behavior.
- The inline renderer chooses between normal horizontal **Motion** Hints and **Text Object Hints** based on the active **Pending Command Prefix**.
- **Text Object Hints** have configuration separate from normal **Motion** Hints and **Gutter Hints**.
- **Text Object Hints** are part of default Hint behavior and do not have a separate disable option.
- Initial **Text Object Hints** include positional delimiters and quotes, plus word and big-word **Availability Text Object Hints**.
- A **Spatial Text Object Hint** anchors a **Text Object Hint** to one or more visible buffer characters to help the user understand the range affected by the next key.
- A **Range Preview** shows what a text object command would affect if completed with the hinted key.
- An **Availability Text Object Hint** indicates that a text object is available without claiming a precise buffer position.
- **Availability Text Object Hints** represent valid next keys for the active text-object prefix, not a guarantee that the resulting selection will be semantically useful.
- A **Spatial Text Object Hint** should show the nearest valid text object for each candidate key, matching what the next key would choose.
- A **Spatial Text Object Hint** may render multiple anchors when a single text object has multiple visible boundaries.
- Paired delimiter **Spatial Text Object Hints** should render each delimiter's literal key at its boundary, such as `(` on the opening parenthesis and `)` on the closing parenthesis.
- Quote **Spatial Text Object Hints** should render the quote key on both quote boundaries.
- A **Spatial Text Object Hint** may include a **Range Preview** in addition to boundary key labels.
- **Range Previews** are shown for **Spatial Text Object Hints**, not **Availability Text Object Hints**.
- A **Range Preview** should only appear when Precognition can model the affected range faithfully; otherwise the **Spatial Text Object Hint** should show boundary labels without a range preview.
- Initial **Range Preview** support is limited to current-line ranges; multiline range previews are deferred until designed separately.
- Initial **Spatial Text Object Hint** support is limited to text objects whose visible boundaries are both on the current line.
- Inside and around text-object prefixes may share boundary anchors while using different **Range Previews**.
- Overlapping **Range Previews** should stack to show nesting, with a small deterministic cap on visible range layers.
- Stacked **Range Preview** layers are ordered by text-object nesting first and **Hint Priority** breaks ties for equivalent or ambiguous ranges.
- Positional **Text Object Hints** may reuse existing Motion-source calculations internally, but they remain text-object concepts in the domain language.
- The same **Text Object Hints** should appear for selection, deletion, and change prefixes because the operator does not change which text objects are available.
- Initial text-object **Pending Command Prefix** support includes selection, delete, change, and yank prefixes.
- In visual mode, `i` and `a` are text-object **Pending Command Prefixes** even without a leading `v`.
- Rendering **Text Object Hints** in visual mode must preserve the active visual selection and its anchor.
- Raw typed keys identify candidate **Pending Command Prefixes**, while the current Vim mode determines whether a candidate prefix is active.
- Initial text-object **Pending Command Prefix** support targets directly typed prefixes; mapping-expanded prefixes are out of scope until designed separately.
- Counted text-object range previews are out of scope initially; counts may still allow **Text Object Hints** to show available candidate keys.
- A text-object **Pending Command Prefix** ends when a key completes or invalidates it, the cursor moves, the user enters insert or command-line mode, the buffer is left, or the user cancels with `Esc` or `Ctrl-C`.
- **Counted Motion** Hints are part of default Hint behavior and do not have a separate disable option.
- Eyeliner-style `f` / `F` Hints are intended to be part of default Hint behavior once implemented.
- A **Target Character Hint** previews a character-specific `f` or `F` Motion, not a word-boundary Motion.
- Initial **Target Character Hints** should target the first same-line occurrence of each unique character.
- **Target Character Hints** show both forward `f` targets and backward `F` targets at the same time.
- Before the user starts a targeted `f` or `F` Motion, **Target Character Hints** render the targeted Motion key (`f` or `F`) rather than the target character.
- Targeted Motion key labels such as `f` and `F` may use a distinct highlight from normal **Motion** Hints to distinguish the two-key interaction.
- While a targeted `f` or `F` Motion is pending, **Target Character Hints** render the reachable target character for the pending Motion direction only.
- While a targeted `f` or `F` Motion is pending, static normal **Motion** Hints are suppressed.
- After a targeted `f`, `F`, `t`, or `T` Motion has been used, **Target Character Hints** show `;` for the next repeat **Destination** and `,` for the reverse repeat **Destination** when those same-line repeats are available.
- Existing normal **Motion** Hints take priority over **Target Character Hints** when they share a **Destination**.
- **Target Character Hints** include punctuation targets and exclude whitespace targets.
- **Target Character Hints** are case-sensitive because `f` and `F` character searches are case-sensitive.
- **Target Character Hints** exclude the character under the cursor because `f` and `F` search away from the cursor.
- **Target Character Hint** uniqueness is tracked separately for forward `f` targets and backward `F` targets.
- **Target Character Hints** scan the entire current line, matching same-line `f` and `F` Motion behavior.
- Initial **Target Character Hints** are limited to single-width printable non-whitespace characters.
- **Target Character Hints** respect a leading **Motion Count**, so `2f` and `2F` preview the second reachable occurrence of each target character in the chosen direction.
- **Target Character Hints** may be supplied through Precognition's Motion extension path rather than hard-coded to built-in Motion behavior.
- Targeted-motion Hint behavior is configured separately from static normal **Motion** Hints because targeted motions can produce multiple dynamic **Destinations** and labels.
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
