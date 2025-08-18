
--
-- This function will run a command and update a window with the commands output, it will only run 1 command at a time
-- You can close the window by pressing esc, it will only display 1 window at a time so if you open a new window the old one will be closed
--
-- This function is a little messy and bad, buuuut... it works TODO: fix???
--

-- This is so that we only run 1 command at a time
local cmd_with_window_running = false
-- This is so we close the window if we want to run a new command
local win_global

function run_command_with_window(command)
	-- If we are already running a command then return
	if cmd_with_window_running then return end
	cmd_with_window_running = true

	if win_global ~= nil then
		if vim.api.nvim_win_is_valid(win_global) then
			vim.api.nvim_win_close(win_global, true)
		end
	end

	-- The data that we get from stdout and sdterr
	local output_lines = {}

	-- The time for the box to dissapear
	local exit_time = 700
	-- The time for the box to dissapear on error
	local err_exit_time = 40000

	local get_max_width = function()
		-- Calculate dynamic dimensions
		local max_width = 0
		for _, line in ipairs(output_lines) do
			local len = vim.fn.strdisplaywidth(line)
			if len > max_width then
				max_width = len
			end
		end

		return max_width
	end

	local buf = vim.api.nvim_create_buf(false, true)

	local win

	-- Create floating window
	local init_window = function ()
		win = vim.api.nvim_open_win(buf, false, {
			relative = "editor",
			row = 0,
			col = 0,
			width= 1,
			height = 1,
			style = "minimal",
			border = "rounded",
		})

		-- Make the window a little transparent
		vim.api.nvim_win_set_option(win, "winblend", 10)

		win_global = win
	end

	-- Close function
	local function close_float()
  	if vim.api.nvim_win_is_valid(win) then
    	vim.api.nvim_win_close(win, true)
  	end
	end

	-- Map <Esc> to close it
	vim.keymap.set('n', '<Esc>', close_float, { noremap = true, silent = true, buffer = 0 })

	-- Update the windows config and the buffers content
	local update_window = function()
		local max_width = get_max_width()

		-- Update the buffer
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)

		-- Create some properties for the window
		local width = math.min(max_width + 4, vim.o.columns - 4) -- add padding and don't exceed screen
		local height = math.min(#output_lines, math.floor(vim.o.lines / 2.4))
		local row = 1
		local col = math.floor((vim.o.columns - width) / 2)

		height = math.max(height, 1)

		-- If the window isnt inited then init it
		if not win then
			init_window()
		end

		-- Set the options
		vim.api.nvim_win_set_config(win, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
		})

		-- Scroll to bottom in the window
    local line_count = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(win, { line_count, 0 })
	end

	vim.fn.jobstart(command, {
		stdout_buffered = false,
		on_stderr = function(_, data)
			if data and #data > 0 then
				-- Check the lines, remove training new_lines
				for _, line in ipairs(data) do
					local clean = line:gsub("[\r\n]+$", "")
					if clean ~= "" then
						exit_time = err_exit_time
					end
					table.insert(output_lines, clean)
				end
				update_window()
  		end
		end,
		on_stdout = function(_, data)
			if data and #data > 0 then
				-- Check the lines, remove training new_lines
				for _, line in ipairs(data) do
					local clean = line:gsub("[\r\n]+$", "")
					if clean ~= "" then
						table.insert(output_lines, clean)
					end
				end
				update_window()
  		end
		end,
		on_exit = function(_,_,_)
			-- The command is no longer running
			cmd_with_window_running = false

			-- Make it so the window closes after a certain amount of time
			vim.defer_fn(function()
				close_float()
			end, exit_time)
		end
	})

end
