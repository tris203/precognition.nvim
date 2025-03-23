local vanilla_horizontal_motions = require("precognition.motions.vanilla_motions.horizontal_motions")
local vanilla_vertical_motions = require("precognition.motions.vanilla_motions.vertical_motions")

---@type Precognition.MotionsAdapter
return vim.tbl_extend("force", vanilla_horizontal_motions, vanilla_vertical_motions)
