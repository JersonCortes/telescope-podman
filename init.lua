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
	local job = plenary.job:new(command):sync()

	local containers = vim.json.decode(table.concat(job, '\n'))
	local entries = {}
	for _, container in ipairs(containers) do
		table.insert(entries, vim.json.encode(container))
	end
	return entries
end


M.show_containers = function(opts)
	pickers.new(opts,{
		finder = finders.new_dynamic({
			fn = function()
				return M._assemble_command('ps -a')
			end,
			entry_maker = function(entry)
				local parsedJson = vim.json.decode(entry)
				if parsedJson then
					return {
						value = parsedJson,
						display = table.concat(parsedJson.Names, ", "),  -- Handles multiple names
						ordinal = table.concat(parsedJson.Names, ", ")
					}
				else
					return nil
				end
			end,
		}),

		sorter = config.generic_sorter(opts),

		previewer = previewers.new_buffer_previewer({
			title = "Container details",
			define_preview = function(self, entry)
				if entry and entry.value then
					local container = entry.value
					local labels_content = {}
					for label, value in pairs(container.Labels or {}) do
						table.insert(labels_content, '  - ' .. label .. ': ' .. value)
					end
					local display = {
						'# ID: ' .. (container.Id or 'N/A'),
						'',
						'*Names*: ' .. (table.concat(container.Names, ' ') or 'N/A'),
						'*Command*: ' .. (table.concat(container.Command, ' ') or 'N/A'),
						--'*Labels*: ' .. (table.concat(labels_content, "\n")),
						'',
						'*Image*: ' .. (container.Image or 'N/A'),
						'*Mounts*: ' .. (vim.inspect(container.Mounts) or 'N/A'),
						'*Networks*: ' .. (vim.inspect(container.Networks) or 'N/A'),
						--'*Ports*: ' .. (vim.inspect(container.Ports) or 'N/A'),
						'',
						'*State*: ' .. (container.State or 'N/A'),
						'*Status*: ' .. (container.Status or 'N/A'),
						'*CreatedAt*: ' .. (container.CreatedAt or 'N/A'),
					}

					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, display)
					utils.highlighter(self.state.bufnr, 'markdown')
				else
					log.error("Invalid entry for preview:", entry)
				end
			end
		})

	}):find()
end

M.show_images = function(opts)
	pickers.new(opts,{
		finder = finders.new_dynamic({
			fn = function()
				return M._assemble_command('images')
			end,
			entry_maker = function(entry)
				local parsedJson = vim.json.decode(entry)
				if parsedJson then
					return {
						value = parsedJson,
						display = table.concat(parsedJson.Names, ", "),  -- Handles multiple names
						ordinal = table.concat(parsedJson.Names, ", ")
					}
				else
					return nil
				end
			end,
		}),

		sorter = config.generic_sorter(opts),

		previewer = previewers.new_buffer_previewer({
			title = "Container details",
			define_preview = function(self, entry)
				if entry and entry.value then
					local container = entry.value
					local labels_content = {}
					for label, value in pairs(container.Labels or {}) do
						table.insert(labels_content, '  - ' .. label .. ': ' .. value)
					end
					local display = {
						'# ID: ' .. (container.Id or 'N/A'),
						'',
						'*Names*: ' .. (table.concat(container.Names, ' ') or 'N/A'),
						--'*Labels*: ' .. (table.concat(labels_content, "\n")),
						'',
						'*Networks*: ' .. (vim.inspect(container.Networks) or 'N/A'),
						--'*Ports*: ' .. (vim.inspect(container.Ports) or 'N/A'),
						'',
						'*Containers*: ' .. (container.Containers or 'N/A'),
						'*Size*: ' .. (container.Size or 'N/A'),
						'*Status*: ' .. (container.Status or 'N/A'),
						'*CreatedAt*: ' .. (container.CreatedAt or 'N/A'),
					}

					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, display)
					utils.highlighter(self.state.bufnr, 'markdown')
				else
					log.error("Invalid entry for preview:", entry)
				end
			end
		})

	}):find()
end


M.show_images()

return M
