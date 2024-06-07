local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local config = require('telescope.config').values

local log = require('plenary.log'):new()
log.level = 'debug'

local M = {}

M.show_containers = function(opts)
	pickers.new(opts,{
		finder = finders.new_async_job({
			command_generator = function ()
				return {"podman", "images", "--format", "json"}
			end,

			entry_maker = function (entry)
				log.debug(entry)
				local parsed = vim.json.decode(entry)
				log.debug(parsed)
				return {
					value = entry,
					display = entry.name,
					ordinal = entry.name,
				}
			end
		}),

		sorter = config.generic_sorter(opts),

		previewer = previewers.new_buffer_previewer({
			title = "Container Image details",
			define_preview = function (self, entry)
				vim.api.nvim_buf_set_lines(
					self.state.bufnr,
					0,
					0,
					true,
					vim.tbl_flatten({
					"test",
					"testing",
					"```lua",
					vim.split(vim.inspect(entry.value), "\n"),
					"```"
					})
				)
			utils.highlighter(self.state.bufnr, 'markdown')
			end
		})

	}):find()
end

M.show_containers()

return M
