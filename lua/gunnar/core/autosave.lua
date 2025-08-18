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
	-- If there is no pattern then return
	if pattern == "" then 
		vim.notify("Invalid Pattern")
		return
	end
	local command = vim.split(vim.fn.input("Command: "), " ")

	attach_to_buffer(pattern, command)
end, {desc = "Runs a command when a file following a pattern is saved"})
