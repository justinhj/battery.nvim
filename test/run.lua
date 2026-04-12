-- Simple test runner for plain Lua files
local spec_target = _G.arg[1] or "spec"
local spec_files = {}

-- Basic globbing for a directory or single file
if vim.fn.isdirectory(spec_target) == 1 then
  local files = vim.fn.globpath(spec_target, '**/*_spec.lua', false, true)
  for _, f in ipairs(files) do table.insert(spec_files, f) end
else
  table.insert(spec_files, spec_target)
end

local has_errors = false
for _, file in ipairs(spec_files) do
  print("\nLoading spec: " .. file)
  local ok, err = pcall(dofile, file)
  if not ok then
    print("\nError in spec: " .. file)
    print(err)
    has_errors = true
  end
end

if has_errors then
  print("\nTests failed!")
  os.exit(1)
else
  print("\nAll tests passed successfully!")
  os.exit(0)
end
