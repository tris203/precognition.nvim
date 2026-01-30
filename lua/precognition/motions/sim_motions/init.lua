local vanilla_vertical_motions = require("precognition.motions.vanilla_motions.vertical_motions")
local sim_horizontal_motions = require("precognition.motions.sim_motions.horizontal_motions")

---@type Precognition.MotionsAdapter
return vim.tbl_extend("force", sim_horizontal_motions, vanilla_vertical_motions)
