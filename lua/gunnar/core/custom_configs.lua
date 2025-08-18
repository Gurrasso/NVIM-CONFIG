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

-- Check for a .nvim.lua file in the project and ask if we want to run it
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
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
						-- y or no input will run it
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
})

