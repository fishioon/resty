
local http = require 'resty.http'
local lrucache = require "resty.lrucache"

local zhihu_pfx = 'http://www.zhihu.com'
local cache = lrucache.new(200)

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

local function get_zhihu_joke_collect()
    math.randomseed(ngx.time())
    local ran_num = math.random(1, 7)
    return get_all_answers(res.body)
end

local function get_zhihu_page_joke(page_num)
    local url = zhihu_pfx .. '/collection/37895484?page=' .. page_num
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
    while true do
        local res = get_zhihu_page_joke(page)
        if res == nil then
            break
        end
    end
end

function _M.random_joke()
    local res = cache:get('joke')
    if res == nil then
        res = get_zhihu_joke_collect()
        cache:set('joke', res, 2) -- 1 sec
    end
    return res
end

function _M.reload_joke()
end

return _M
