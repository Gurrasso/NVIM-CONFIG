--
--  This allows me to run a command when i save a certain type of file and have the output displayed
--

attach_to_buffer = function(pattern, command)

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(pattern, {clear = true}),
		pattern = pattern,
		callback = function()
			run_command_with_window(command)
		end,
	})
end

vim.api.nvim_create_user_command("AutoSave", function()
	print "AutoSave starting..."
	local pattern = vim.fn.input("Pattern: ")
	local command = vim.split(vim.fn.input("Command: "), " ")

	if not command or not pattern then return end

	attach_to_buffer(pattern, command)
end, {})
