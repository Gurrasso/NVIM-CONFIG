--
--  This allows me to run a command when i save a certain type of file and have the output displayed
--

local attach_to_buffer = function(pattern, command)

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(pattern, {clear = true}),
		pattern = pattern,
		callback = function()
			-- The data that we get from stdout and sdterr
			local out_output_lines = {}
			local err_output_lines = {}
			local output_lines = {}

			-- If we have any error data
			local has_error_data = false

			-- The time for the box to dissapear
			local exit_time = 700
			-- The time for the box to dissapear if we have an error
			local err_exit_time = 5000

			vim.fn.jobstart(command, {
				stdout_buffered = true,
				on_stderr = function(_, data)
					if data and #data > 0 then
						vim.list_extend(err_output_lines, data)

						-- Remove empty string lines (can happen due to trailing newlines)

						-- Check if we have any real error data
      			for _, line in ipairs(data) do
        			if line ~= "" then
          			has_error_data = true
								-- 
								exit_time = err_exit_time
          			break
        			end
      			end
					end
				end,
				on_stdout = function(_, data)
					if data and #data > 0 then
						vim.list_extend(out_output_lines, data)
					end
				end,
				on_exit = function(_,_,_)

					-- If we have error data we dont want to display the other things(i just want to display the error)
					if has_error_data == false then
						vim.list_extend(output_lines, out_output_lines)
					else
						vim.list_extend(output_lines, err_output_lines)
					end

					-- Create a buffer
					local buf = vim.api.nvim_create_buf(false, true)

					-- Set buffer lines
					vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)

					-- Calculate dynamic dimensions
					local max_width = 0
					for _, line in ipairs(output_lines) do
						local len = vim.fn.strdisplaywidth(line)
						if len > max_width then
							max_width = len
						end
					end

					-- Create some properties for the window
					local width = math.min(max_width + 4, vim.o.columns - 4) -- add padding and don't exceed screen
					local height = math.min(#output_lines, vim.o.lines - 4)
					local row = 1
					local col = math.floor((vim.o.columns - width) / 2)


					-- Create floating window
					local win = vim.api.nvim_open_win(buf, false, {
						relative = "editor",
						width = width,
						height = height,
						row = row,
						col = col,
						style = "minimal",
						border = "rounded",
					})

					vim.api.nvim_win_set_option(win, "winblend", 10)

					vim.defer_fn(function()
						if vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_close(win, true)
						end
					end, exit_time)
				end
			})
		end,
	})
end

vim.api.nvim_create_user_command("AutoSave", function()
	print "AutoSave starting..."
	local pattern = vim.fn.input("Pattern: ")
	local command = vim.split(vim.fn.input("Command: "), " ")

	attach_to_buffer(pattern, command)
end, {})
