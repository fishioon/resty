
local http = require 'resty.http'
local zhihu_pfx = 'http://www.zhihu.com'
local joke_count = 0
local jokes = {}
local last_random_index = 0

local _M = {}

local function parse_joke_page(html_text)
    local sstr = 'data%-entry%-url="'
    local off_start = 1
    local off_end = 1
    local res = {}
    local i = 1
    while true do
        off_start, off_end = string.find(html_text, sstr, off_start)
        if (off_start == nil) then
            break
        end
        off_start = string.find(html_text, '">', off_end+1)
        if (off_start == nil) then
            break
        end
        local answer = string.sub(html_text, off_end+1, off_start-1)
        res[i] = answer
        i = i+1

        off_start = off_start + 1
    end
    if next(res) == nil then
        return nil
    end
    return res
end

local function get_zhihu_page_joke(page_num)
    local url = zhihu_pfx .. '/collection/37895484?page=' .. page_num
    ngx.log(ngx.INFO, 'url:', url)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, { method = 'GET' })
    if res == nil then
        ngx.log(ngx.ERR, 'http get failed, url:', url, ' err:', err)
        return nil
    end
    return parse_joke_page(res.body)
end

local function reload_joke()
    local page = 1
    local index = 0
    while true do
        local res = get_zhihu_page_joke(page)
        if res == nil then
            break
        end
        for k, v in ipairs(res) do
            index = index + 1
            jokes[index] = v
        end
        page = page + 1
    end
    joke_count = index
    return joke_count
end

function _M.random_joke()
    if joke_count == 0 then
        return nil
    end
    math.randomseed(ngx.time())
    local index = math.random(1, joke_count)
    while last_random_index == index do
        index = math.random(1, joke_count)
    end
    last_random_index = index
    ngx.log(ngx.INFO, 'random:', index)
    return zhihu_pfx..jokes[index]
end

function _M.reload_joke()
    return reload_joke()
end

return _M
