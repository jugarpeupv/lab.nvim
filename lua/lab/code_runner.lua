--[[

lab.nvim
Copyright: (c) 2022, Dan Peterson <hi@dan-peterson.ca>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

--]]

local api = vim.api
local Panel = require 'lab.panel'
local VirtualText = require 'lab.virtual_text'
local Process = require 'lab.process'

local CodeRunner = {}

local state = {
	active = false,
	instances = {},
	instance_count = 0,
}

local supported_extensions = { [".js"] = true }

function CodeRunner.run()

	-- vim.api.nvim_get_current_buf(),
	local buf_handle = vim.fn.bufnr('%')
	local file_path = api.nvim_buf_get_name(0)
	

	-- Resume if paused.
	if state.instances[file_path] and state.instances[file_path].paused == true then
		state.instances[file_path].paused = false
		CodeRunner.resume()
		return
	end

	-- Stop and re-run if active.
	if state.instances[file_path] then
		CodeRunner.update(file_path)
		return
	end
	
	-- Check the file type is supported.
	local file_extension = file_path:match("^.+(%..+)$")
	local is_supported = supported_extensions[file_extension]

	if not is_supported then
		return
	end

	local run_id = os.time()

	state.instances[file_path] = { buf_handle = buf_handle, run_id = run_id }
	state.instance_count = state.instance_count + 1

	if (state.instance_count == 1) then
		Process:start(CodeRunner.handler)
	end

	Process:send({ jsonrpc = "2.0", id = file_path, method = "Lab.Runner.Start", params = { file = file_path } })
	Panel:write("## Executing: `" .. file_path .. "` Run ID: " .. run_id)
end

function CodeRunner.update(file_path)
	local is_instantiated = state.instances[file_path]
	if not is_instantiated then return end

	local buf_handle = state.instances[file_path].buf_handle
	local run_id = os.time()
	state.instances[file_path].run_id = run_id

	Panel:write("## Executing: `" .. file_path .. "` Run ID: " .. run_id)

	Process:send({ jsonrpc = "2.0", id = file_path, method = "Lab.Runner.Stop", params = { file = file_path } })

	vim.defer_fn(function()
		Process:send({ jsonrpc = "2.0", id = file_path, method = "Lab.Runner.Start", params = { file = file_path } })
	end, 1)

	vim.defer_fn(function()
		VirtualText:clear(buf_handle, run_id)
	end, 100)

end

function CodeRunner.stop()

	-- vim.api.nvim_get_current_buf(),
	local buf_handle = vim.fn.bufnr('%')
	local file_path = api.nvim_buf_get_name(0)

	state.instances[file_path] = nil
	state.instance_count = state.instance_count - 1

	VirtualText:clearAll(buf_handle)
	Process:send({ jsonrpc = "2.0", id = file_path, method = "Lab.Runner.Stop", params = { file = file_path } })
	Panel:write("- Stopped on " .. file_path)

	if (state.instance_count == 0) then
		Process:stop()
	end

end

function CodeRunner.resume()
	local buf_handle = vim.fn.bufnr('%')
	local file_path = api.nvim_buf_get_name(0)

	vim.defer_fn(function()
		if state.instances[file_path].paused_line then
			VirtualText:delete(buf_handle, state.instances[file_path].paused_line.mark_id, state.instances[file_path].paused_line.line_num) 
		end
	end, 1)

	Process:send({ jsonrpc = "2.0", id = file_path, method = "Lab.Runner.Resume", params = { file = file_path } })
end

function CodeRunner.panel()
	if Panel.is_open then
		Panel:close()
	else
		Panel:open()
	end
end

function CodeRunner.setup()
	if state.active == true then return end
	Panel:init()
	api.nvim_exec([[
	  augroup lab
	  au!
	  au VimLeavePre   * call v:lua.require'lab.code_runner'.stop()
	  au BufWritePost  * call v:lua.require'lab.code_runner'.update(expand('%:p'))
	  augroup END
	]], false)
	state.active = true;
	Panel:write("# code runner setup complete.")
end

function CodeRunner.handler(msg)
	
	if not msg.method then return end;

	local buf_handle = state.instances[msg.params.file].buf_handle
	local run_id = state.instances[msg.params.file].run_id

	if (msg.params.event == "complete") then
		vim.defer_fn(function()
			Panel:write("- Execution complete.")
		end, 1)
	end

	if (msg.params.event == "log") then
		local highlights = {
			info = "DiagnosticVirtualTextInfo",
			trace = "DiagnosticVirtualTextInfo",
			error = "DiagnosticVirtualTextError",
			warning = "DiagnosticVirtualTextWarn",
			debug = "Visual"
		}
		vim.defer_fn(function()
			VirtualText:render({
				run_id = run_id,
				buf_handle = buf_handle,
				line_num = msg.params.line,
				text = msg.params.text,
				hl = highlights[msg.params.type] or nil
			})
			Panel:write("- [" .. (msg.params.line + 1) .. "] " .. msg.params.text)
		end, 1)
	end

	if (msg.params.event == "error") then
		vim.defer_fn(function()
			VirtualText:render({
				run_id = run_id,
				buf_handle = buf_handle,
				line_num = msg.params.line,
				text = msg.params.text,
				hl = "DiagnosticVirtualTextError",
				icon = "",
			})
			Panel:write("- [" .. (msg.params.line + 1) .. "] " .. msg.params.description)
		end, 1)
	end

	if (msg.params.event == "paused") then
		state.instances[msg.params.file].paused = true
		vim.defer_fn(function()
			state.instances[msg.params.file].paused_line = VirtualText:render({
				run_id = run_id,
				buf_handle = buf_handle,
				line_num = msg.params.line,
				text = msg.params.text,
				hl = 'DiagnosticVirtualTextWarn',
				append = false,
				icon = '',
			})
			Panel:write("- [" .. (msg.params.line + 1) .. "] " .. msg.params.text)
		end, 1)

	end
end

return CodeRunner
