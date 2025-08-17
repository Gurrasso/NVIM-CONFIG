--
-- A package that allows me to use a keybind to run a certain cmd that i can set
--

vim.g.mapleader = " "

vim.api.nvim_create_user_command("AutoRun", function()
	print "AutoRun starting..."
	local command = vim.fn.input("Command: ")

	run_function = function()
		os.execute(command)
	end

	vim.keymap.set("n", "<leader>r", run_function)
end, {})
