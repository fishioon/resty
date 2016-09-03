
local xml = require("lib.xmlSimple").newParser()
local str = require 'resty.string'
local cjson = require 'cjson'
local models = require 'models'
local token_ = 'fishioon'
local admin_uid_ = 'olM6ms0pCy7zQPSZbkmhalGYEe3o'

local _M = {}

local function _check_signature(signature, timestamp, nonce)
    local tmptab = { token_, timestamp, nonce }
    table.sort(tmptab)
    local tmpstr = table.concat(tmptab)
    tmpstr = ngx.sha1_bin(tmpstr)
    tmpstr = str.to_hex(tmpstr)
    ngx.log(ngx.INFO, 'signature:', signature)
    ngx.log(ngx.INFO, 'result:', tmpstr)
    return signature == tmpstr
end

local function _parse_msg(xml_msg)
    ngx.log(ngx.INFO, 'recv msg:', xml_msg)
    local res = xml:ParseXmlText(xml_msg)
    local root = res.xml
    local wx_msg = {
        from_uid = string.sub(root.FromUserName:value(), 10, -4),
        to_uid = string.sub(root.ToUserName:value(), 10, -4),
        content = string.sub(root.Content:value(), 10, -4),
        msg_type = string.sub(root.MsgType:value(), 10, -4),
        create_time = root.CreateTime:value()
    }
    ngx.log(ngx.INFO, 'content:', wx_msg.content)
    return wx_msg
end

local function _packet_msg(msg, content)
    local msg_template = [==[<xml>
                <ToUserName><![CDATA[%s]]></ToUserName>
                <FromUserName><![CDATA[%s]]></FromUserName>
                <CreateTime>%s</CreateTime>
                <MsgType><![CDATA[%s]]></MsgType>
                <Content><![CDATA[%s]]></Content>
                <FuncFlag>0</FuncFlag>
                </xml>]==]
    local res = string.format(msg_template, msg.from_uid, msg.to_uid,
                              msg.create_time, msg.msg_type, content)
    return res
end

local function _help()
    local help = '使用说明: 输入xh随机出现一个笑话'
    return help
end

function _M.check_signature()
    local args = ngx.req.get_uri_args()
    local signature = args.signature
    local timestamp = args.timestamp
    local nonce = args.nonce
    local echostr = args.echostr
    if _check_signature(signature, timestamp, nonce) == true then
        return echostr
    else
        return 'signature failed'
    end
end

local function handle_msg(wx_msg)
    -- trim
    local result = ''
    local text = (wx_msg.content:gsub("^%s*(.-)%s*$", "%1"))
    if text:sub(1, 1) == '#' then
        local off = text:find('#', 2)
        if off then
            local content = ''
            local theme = text:sub(2, off-1)
            if theme then
                content = text:sub(off+1)
            end
            models.add_mark(wx_msg.from_uid, theme, content)
            result = theme .. ' success'
        end
    else
        local blank_off = text:find(' ', 1)
        local cmd = text
        local content = ''
        if blank_off then
            cmd = text:sub(1, blank_off-1):lower()
            content = text:sub(blank_off+1)
        end
        if cmd == 'sj' then
            local num = 100
            if content ~= '' then
                num = tonumber(content)
            end
            result = models.random_num(1, num)
        elseif cmd == 'xh' then
            result = models.random_joke()
        elseif cmd == 'mk' then
            local marks = models.get_marks(wx_msg.from_uid)
            result = cjson.encode(marks)
        elseif cmd == 'jj' then
            if wx_msg.from_uid == admin_uid_ then
                local res = models.reload_joke()
                reuslt = 'jokes:' .. res
            end
        else
        end
    end
    if result == '' then
        result = _help()
    end
    return result
end

function _M.process_msg(xml_msg)
    local wx_msg = _parse_msg(xml_msg)
    local data = handle_msg(wx_msg)
    return _packet_msg(wx_msg, data)
end

return _M
