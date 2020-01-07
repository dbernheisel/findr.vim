local M = {}
local vim = vim

local function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a '..directory..'')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = {}
        if vim.api.nvim_call_function('isdirectory', {filename}) == 1 then
            t[i]['display'] = filename .. '/'
        else
            t[i]['display'] = filename
        end
        t[i]['value'] = filename
    end
    pfile:close()
    table.sort(t, function(a,b)
        a = a['display']
        b = b['display']
        if a == './' then
            return true
        elseif b == './' then
            return false
        elseif a == '../' then
            return true
        elseif b == '../' then
            return false
        elseif string.len(a) == string.len(b) then
            return a < b
        else
            return string.len(a) < string.len(b)
        end
    end)
    return t
end

function M.table()
    return scandir('.')
end

function M.sink(selected)
    return 'edit '.. selected
end

function M.prompt()
    local cwd = vim.api.nvim_call_function('getcwd', {})
    cwd = vim.api.nvim_call_function('pathshorten', {cwd})
    cwd = cwd == '/' and '/' or cwd .. '/'
    return cwd
end

M.filetype = 'findr-files'
M.history = true

return M
