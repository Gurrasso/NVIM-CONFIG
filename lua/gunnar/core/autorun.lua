--
-- A package that allows me to use a keybind to run a certain cmd that i can set
--

vim.api.nvim_create_user_command("AutoRun", function()
	print "AutoRun starting..."

	local command = vim.split(vim.fn.input("Command: "), " ")
	-- If there is no command then return
	if command[0] == nil then 
		vim.notify("Invalid command")
		return
	end


	local run_function = function()
		run_command_with_window(command)
	end

	vim.keymap.set("n", "<leader>r", run_function)
end, {desc = "Maps <leader>r to a command"})
