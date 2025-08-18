--
-- This saves trusted configs to a json and also loads project configs
--
-- If the config isnt trusted it will ask what you want to do. You can load it with "y" or "" trust it with "t" and do nothing
--

local json = vim.fn.json_decode
local encode = vim.fn.json_encode

local trust_file = vim.fn.stdpath("config") .. "/trusted_configs.json"

-- Load trusted configs from json
local function load_trusted_configs()
  local ok, content = pcall(vim.fn.readfile, trust_file)
  if not ok or not content then return {} end

  local success, parsed = pcall(function()
		return json(table.concat(content, "\n"))
	end)

	return success and parsed or {}
end

-- Save trusted configs to json
local function save_trusted_configs(configs)
	local data = encode(configs)
  local f = io.open(trust_file, "w")
  if f then
    f:write(data)
    f:close()
  else
    vim.notify("Failed to write trusted config file", vim.log.levels.ERROR)
  end
end

-- Run a file and print an error
local run_file = function(filename)
	local ok, err = pcall(dofile, filename)
	if not ok then
		vim.notify("Error running " .. filename .. ": " .. err, vim.log.levels.ERROR)
	end
end

local check_configs = function()
	-- Get current working directory when nvim starts
	local cwd = vim.fn.getcwd()
	-- Will check the dir where we launched nvim and the parent dir of where we launched nvim
	local files_to_check_relative = { "/.nvim.lua","/../.nvim.lua" }
	local trusted_configs = load_trusted_configs()

	-- Loop through the files to check
	for _, file_to_check_relative in ipairs(files_to_check_relative) do

		-- Get the full path of the file to check and normalize it
		local file_to_check = vim.loop.fs_realpath(cwd.. file_to_check_relative)

		-- Check if a file exists and ask if we want to run it
		if vim.fn.filereadable(file_to_check) == 1 then
				-- Checks if its already trusted
			if trusted_configs[file_to_check] then
				run_file(file_to_check)
			else
				vim.ui.input({ prompt = "Run project Lua config at " .. file_to_check_relative .. "? (y/n/t[rust]): " }, function(input)
					-- y or no input("") will run it
					-- t will add it to the trusted configs and run it
					-- anything else will not run it
					if input and (vim.fn.tolower(input) == "y" or input == "") then
						run_file(file_to_check)
					elseif input and vim.fn.tolower(input) == "t" then
						trusted_configs[file_to_check] = true
						save_trusted_configs(trusted_configs)
						run_file(file_to_check)
					end
				end)
			end
		end
	end
end

-- Check for a .nvim.lua file in the project and ask if we want to run it
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.defer_fn(function()
			check_configs()
		end, 100)
	end
})

vim.api.nvim_create_user_command("CheckConfigs", function()
	check_configs()
end,{desc = "Check for configs"})

local list_trusted_win

--
-- Lists trusted configs and allowes me to remove them by pressing d
--
vim.api.nvim_create_user_command("ListTrustedConfigs", function()

	-- Check if we have any trusted condigs
  local ok, content = pcall(vim.fn.readfile, trust_file)
  if not ok or not content then
    vim.notify("No trusted configs found.", vim.log.levels.INFO)
    return
  end

	-- Load the trusted_configs
  local success, configs = pcall(function()
    return json(table.concat(content, "\n"))
  end)

	-- Check if load was successfull
  if not success or type(configs) ~= "table" then
    vim.notify("Failed to parse trusted configs.", vim.log.levels.ERROR)
    return
  end

	if list_trusted_win ~= nil then
		if vim.api.nvim_win_is_valid(list_trusted_win) then
			vim.api.nvim_win_close(list_trusted_win, true)
		end
	end

  -- Create buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  list_trusted_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.6),
    height = math.min(20, vim.o.lines - 4),
    row = 2,
    col = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.6)) / 2),
    style = "minimal",
    border = "rounded",
		title = " Press d to remove a config ",
  	title_pos = "center", -- or "left" / "right"
  })

  -- Store a list of paths (index = line number)
  local display_lines = {"Trusted configs: "}
  local path_by_line = {}
	-- Get the default amount of lines in display_lines
	local def_lines = #display_lines

	-- Check if config exists
  for path, _ in pairs(configs) do
    local exists = vim.fn.filereadable(path) == 1 and "[OK]		" or "[Missing]		"
    table.insert(display_lines, exists .. " " .. path)
    path_by_line[#display_lines] = path
	end

	-- Update the buffer content
	local update_buffers = function()
  	vim.api.nvim_buf_set_option(buf, "modifiable", true)

		-- If there isnt any configs then we say so 
		if #display_lines - def_lines == 0 then
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No trusted configs found." })
		else
			vim.api.nvim_buf_set_lines(buf, 0, -1, false,	display_lines)
		end

  	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	end

	update_buffers()

  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- Close with <Esc>
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(list_trusted_win) then
      vim.api.nvim_win_close(list_trusted_win, true)
    end
  end, { buffer = buf, silent = true })

  -- Delete config with "d"
  vim.keymap.set("n", "d", function()
    local line = vim.fn.line(".")
    local path = path_by_line[line]
    if path and configs[path] then
      configs[path] = nil
      save_trusted_configs(configs)
      table.remove(display_lines, line)
      table.remove(path_by_line, line)

      update_buffers()

      vim.notify("Removed trusted config:\n" .. path)
    end
  end, { buffer = buf, silent = true, desc = "Delete trusted config" })
end, {
  desc = "Interactive list of trusted project configs",
})
