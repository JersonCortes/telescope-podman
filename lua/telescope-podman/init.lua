local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local config = require('telescope.config').values
local finders = require('telescope.finders')
local job = require('plenary.job')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local log = require('plenary.log'):new{
	plugin = "telescope_podman",
	level = "debug"
}

local M = {}

---@param subcommand string
---@return string[]
M._assemble_command = function (subcommand)

	local engine = "podman"
	local aux = "--format json | jq -c"
	local fullCommand = engine .. ' ' .. subcommand .. ' ' .. aux
	local command = {"sh", "-c", fullCommand}

	local jobResult = job:new(command):sync()

	local containers = vim.json.decode(table.concat(jobResult, '\n'))
	local entries = {}
	for _, container in ipairs(containers) do
		table.insert(entries, vim.json.encode(container))
	end

	return entries
end

M._refresh_picker = function(prompt_bufnr)
	--work in progress
	--State stays as "stopping" since it updates pretty fast. fix it (?)
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local finder = current_picker.finder
	finder._finder_fn = function()
		return M._assemble_command('ps')
	end
	current_picker:refresh(finder, { reset_prompt = true })
end

M._start_stop_container = function(container)
	local engine = "podman"
	local args = {}

	if container.value.State == "exited" then
		args = "start" .. ' ' .. container.display
	else
		args = "stop" .. ' ' .. container.display
	end

	local subcommand = engine .. ' ' .. args
	local command = {"sh", "-c", subcommand}

	job:new(command):start()
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
		}),
		attach_mappings = function()
			actions.select_default:replace(function(prompt_bufnr)
				local entry = action_state.get_selected_entry()
				M._start_stop_container(entry)
				M._refresh_picker(prompt_bufnr)
			end)
			return true
		end,
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

		}),
		attach_mappings = function()
			actions.select_default:replace(function()
				local entry = action_state.get_selected_entry()
				--M._delete_image(entry)
			end)
			return true
		end,
	}):find()
end

return M
