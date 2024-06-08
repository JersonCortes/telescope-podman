local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local config = require('telescope.config').values
local plenary = require('plenary')

local log = require('plenary.log'):new()
log.level = 'debug'

local M = {}

---@param subcommand string
---@return string[]
M._assemble_command = function (subcommand)

	local engine = "podman"
	local aux = "--format json | jq -c"
	local fullCommand = engine .. ' ' .. subcommand .. ' ' .. aux
	local command = {"sh", "-c", fullCommand}

	log.debug(command)
    	local job = plenary.job:new(command):sync()
	log.debug(job)
	return job
end


M.show_containers = function(opts)
	pickers.new(opts,{
		finder = finders.new_dynamic({
			fn = function ()
				return M._assemble_command 'ps'
			end,

			entry_maker = function (entry)
				log.debug(entry)
				local parsed = vim.json.decode(entry)
				log.debug(parsed)
				log.debug('Accessing: ', parsed[1].Image)
				log.debug('Accessing: ', parsed[2].Image)

				return {
					value = parsed,
					display = parsed[1].Image,
					ordinal = parsed[1].Image,
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
