# 💭👀precognition.nvim

> /ˌpriːkɒɡˈnɪʃn/
> _noun_
>
> 1. foreknowledge of an event, especially as a form of extrasensory perception.

**precognition.nvim** assists with discovering motions (Both vertical and horizontal) to navigate your current buffer

![image](https://github.com/tris203/precognition.nvim/assets/18444302/ea24caee-85da-42d8-b0e9-555b47268643)

## 📦 Installation

Installation with any package manager, Lazy example below:

```lua

return {
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    config = {
    -- startVisible = true,
    -- showBlankVirtLine = true,
    -- highlightColor = { link = "Comment" },
    -- hints = {
    --      Caret = { text = "^", prio = 2 },
    --      Dollar = { text = "$", prio = 1 },
    --      MatchingPair = { text = "%", prio = 5 },
    --      Zero = { text = "0", prio = 1 },
    --      w = { text = "w", prio = 10 },
    --      b = { text = "b", prio = 9 },
    --      e = { text = "e", prio = 8 },
    --      W = { text = "W", prio = 7 },
    --      B = { text = "B", prio = 6 },
    --      E = { text = "E", prio = 5 },
    -- },
    -- gutterHints = {
    --     -- prio is not currently used for gutter hints
    --     G = { text = "G", prio = 1 },
    --     gg = { text = "gg", prio = 1 },
    --     PrevParagraph = { text = "{", prio = 1 },
    --     NextParagraph = { text = "}", prio = 1 },
    -- },
    },
}
```

## ⚙️ Config

- Items can be hidden by settings their priority to 0, if you want to hide the
  entire virtual line. Set all elements to `prio = 0` in combination with the
  below.
- `showBlankVirtLine = false`
  Setting this option will mean that if a Virtual Line would be blank it wont be
  rendered
- highlightColor can be set in two ways:

1. As a table containing a link property pointing to an existing highlight group (see `:highlight` for valid options).
2. As a table specifying custom highlight values, such as foreground and background colors. ([more info](<https://neovim.io/doc/user/api.html#nvim_set_hl()>))

## ❔Usage

### Toggling

The hints can be toggled on and off with

```
:lua require("precognition").toggle()
```

### Peeking

The hints can be peeked, this means that the hint will be show until the next
cursor movement.

```
:lua require("precognition").peek()
```

## 💻 Supported Versions

This plugin supports stable and nightly. >0.9 at the time of writing.

## ✍️ Contributing

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion to improve the plugin, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

If there is something specific you want to work on then, please open an issue/discussion first to avoid duplication of efforts
If you have found a bug please open an issue, or submit a PR with a failing test.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
