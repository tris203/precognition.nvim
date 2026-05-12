# Floating Overlay Hint Rendering

Precognition does not support rendering Inline Hints with floating windows,
overlay extmarks, or fake-transparent popups instead of virtual lines.

## Why this is out of scope

Precognition uses Neovim virtual lines as the rendering model for Inline Hints.
Supporting a second renderer would add a parallel layout system with different
tradeoffs from virtual lines: it can obscure buffer text, needs separate
alignment behavior, and introduces difficult edge cases around wrapping, tabs,
multibyte characters, inlay-hint padding, and text-object hints.

Keeping one rendering method makes Hint behavior easier to reason about and
keeps the implementation focused on showing Motion Destinations consistently.
Configuration that changes where the virtual line appears, such as placing it
above the cursor line, is a separate possibility because it preserves the same
virtual-line rendering model.

## Prior requests

- #44 - "Support virtual line to be floating"
