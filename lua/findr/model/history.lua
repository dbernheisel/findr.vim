local utils = require('findr/utils')
local api = require('findr/api')

local M = {}

local index = 0
local jump_point = -1
local history = {}
local len = 0


local function valid_line(dir_file_pair)
    if utils.tablelength(dir_file_pair) >= 1 then
        return api.call_function('isdirectory', {dir_file_pair[1]}) == 1
    end
    return false
end

function M.reset(cwd, input)
    index = 0
    jump_point = {cwd, input}
end

function M.get_jumpoint()
    return index, jump_point
end

function M.set_jumpoint(idx, item)
    index = idx
    jump_point = item
end

local function join_to(t1, t2)
    for _, val in ipairs(t2) do
        table.insert(t1, val)
    end
end

local function buffers()
    local bufs = vim.api.nvim_list_bufs()
    local t  = {}
    for _, val in ipairs(bufs) do
        local name = vim.api.nvim_buf_get_name(val)
        local bufnr = vim.api.nvim_buf_get_number(val)
        local findrnr = vim.api.nvim_call_function('bufnr', {})
        if  vim.api.nvim_buf_is_loaded(val)  and name ~= '' and bufnr ~=  findrnr  then
            table.insert(t, name)
        end
    end
    return t
end

function M.source()
    history = {}
    len = 0
    local bufs
    local files = buffers()
    join_to(files, vim.api.nvim_get_vvar('oldfiles'))
    local prev_pair = {}
    for _, line in ipairs(files) do
        local split_idx = string.match(line, '^.*()/')
        local dir_file_pair = {string.sub(line, 1, split_idx), string.sub(line, split_idx+1)}
        if  valid_line(dir_file_pair) then
            local dir = dir_file_pair[1]
            local input = dir_file_pair[2]
            if input == nil then
                input = ''
            elseif api.call_function('isdirectory', {dir..input}) == 1 then
                if input == '.' or input == './' then
                    input = ''
                elseif input == '..' or input == '../' then
                    dir = api.call_function('fnamemodify', {dir, ':h:h'})
                    input = ''
                else
                    dir = dir..input
                    input = ''
                end
            end
            dir_file_pair = {dir, input}
            if dir_file_pair[1] ~= prev_pair[1] or dir_file_pair[2] ~= prev_pair[2] then
                table.insert(history, dir_file_pair)
                len = len + 1
            end
        end
        prev_pair = dir_file_pair
    end
end

function M.get()
    if index == 0 then
        return jump_point[1], jump_point[2]
    else
        return history[index][1], history[index][2]
    end
end

function M.next()
    if index > 0 then
        index = (index - 1) % (len + 1)
    else
        index = 0
    end
end

function M.prev()
    if index ~= len then
        index = (index + 1) % (len + 1)
    else
        index = len
    end
end

return M
