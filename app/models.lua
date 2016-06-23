
local http = require 'resty.http'
local lrucache = require "resty.lrucache"

local zhihu_pfx = 'http://www.zhihu.com'
local cache = lrucache.new(200)

local _M = {}

local function get_all_answers(html_text)
    local sstr = [[data%-entry%-url="]]
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
    
    math.randomseed(ngx.time())
    local ran_num = math.random(1, #res)
    return zhihu_pfx .. res[ran_num]
end

local function get_zhihu_joke_collect()
    math.randomseed(ngx.time())
    local ran_num = math.random(1, 7)
    local httpc = http.new()
    local res, err = httpc:request_uri(
        zhihu_pfx .. '/collection/37895484?page=' .. ran_num,
        { method = 'GET' }
    )
    if res == nil then
        return err
    end
    return get_all_answers(res.body)
end

function _M.random_joke()
    local res = cache:get('joke')
    if res == nil then
        res = get_zhihu_joke_collect()
        cache:set('joke', res, 2) -- 1 sec
    end
    return res
end

return _M
