
local http = require 'resty.http'
local mysql = require 'resty.mysql'
local zhihu_pfx = 'http://www.zhihu.com'
local joke_count = 0
local jokes = {}
local last_random_index = 0

local db_conf = {
    host = "127.0.0.1",
    port = 3306,
    database = "online",
    user = "online",
    password = "online_wx",
    max_packet_size = 1024 * 1024
}

local _M = {}

local function db_reconnect()
    db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, 'mysql new failed, err:', err)
        return nil
    end
    local ok, err, errno, sqlstate = db:connect(db_conf)
    if not ok then
        ngx.log(ngx.ERR, 'mysql failed, err:', err, ' errno:',errno, ' sqlstate:', sqlstate)
        return nil
    end
    return db
end


local function db_conn()
    return db_reconnect()
end

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

function _M.add_mark(uid, theme, content)
    local db = db_conn()
    if not db then
        return false, 'db err'
    end
    local sql = string.format([[insert into wx_mark (uid, theme, content, time)
                              value (%s, %s, %s, %d)]],
                              ngx.quote_sql_str(uid),
                              ngx.quote_sql_str(theme),
                              ngx.quote_sql_str(content),
                              ngx.time())
    ngx.log(ngx.INFO, 'add mark sql:', sql)
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR, 'mysql failed, err:', err, ' errno:',errno,' sqlstate:', sqlstate)
        return false
    end
    res, err = db:set_keepalive(10000, 100)
    if not res then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
        return false
    end
    return true
end

function _M.get_marks(uid)
    local db = db_conn()
    if not db then
        return nil, 'db err'
    end
    local sql = string.format([[select theme, content, time from wx_mark where
                              uid='%s' order by id desc limit 10]], uid)
    ngx.log(ngx.INFO, 'add mark sql:', sql)
    local res, err, errno, sqlstate = db:query(sql, 2)
    if not res then
        ngx.log(ngx.ERR, 'mysql failed, err:', err, ' errno:',errno,' sqlstate:', sqlstate)
        return nil
    end
    db:set_keepalive(10000, 100)
    return res
end

function _M.random_num(start_num, end_num)
    math.randomseed(ngx.time())
    return math.random(start_num, end_num)
end

return _M
