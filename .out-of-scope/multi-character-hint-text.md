# Multi-Character Hint Text

Precognition does not currently support replacing a Hint with text that is more
than one displayed character wide.

## Why this is out of scope

Precognition's Inline Hints are aligned to Motion Destinations. A single Hint is
expected to occupy one displayed cell at its Destination, with Hint Priority used
to decide which Hint wins when multiple Hints share the same Destination.

Multi-character Hint text introduces ambiguous overlap cases. For example, two
Hints can have different Destinations but their rendered text can partially
overlap. That raises product and rendering questions that do not currently have
an elegant answer:

- Should the earlier Hint obscure the later one, or should Hint Priority apply
  across every occupied cell?
- If only part of a multi-character Hint overlaps another Hint, should the whole
  Hint disappear, be clipped, or shift?
- How should this interact with tabs, multibyte characters, inlay-hint padding,
  and virtual-line alignment?

Until there is a simple, predictable model for these overlap cases, supporting
multi-character Hint text would make Precognition harder to reason about and
could undermine its core goal: showing where a Motion would land without visual
ambiguity.

## Prior requests

- #101 - "Multi-character hint replacements cause misalignment"
