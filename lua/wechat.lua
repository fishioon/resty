
local xml = require("lib.xmlSimple").newParser()
local str = require 'resty.string'
local cjson = require 'cjson'
local models = require 'models'
local _token = 'fishioon'

local _M = {}

local function _check_signature(signature, timestamp, nonce)
    local tmptab = { _token, timestamp, nonce }
    table.sort(tmptab)
    local tmpstr = table.concat(tmptab)
    tmpstr = ngx.sha1_bin(tmpstr)
    tmpstr = str.to_hex(tmpstr)
    ngx.log(ngx.INFO, 'signature:', signature)
    ngx.log(ngx.INFO, 'result:', tmpstr)
    return signature == tmpstr
end

local function _parse_msg(xml_msg)
    local res = xml:ParseXmlText(xml_msg)
    local root = res.xml
    local wx_msg = {
        from_uid = string.sub(root.FromUserName:value(), 10, -4),
        to_uid = string.sub(root.ToUserName:value(), 10, -4),
        content = string.sub(root.Content:value(), 10, -4),
        msg_type = string.sub(root.MsgType:value(), 10, -4),
        create_time = root.CreateTime:value()
    }
    ngx.log(ngx.INFO, cjson.encode(wx_msg))
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

function _M.process_msg(xml_msg)
    local data = ''
    wx_msg = _parse_msg(xml_msg)
    ngx.log(ngx.INFO, 'content:', wx_msg.content)
    if string.len(wx_msg.content) == 2 then
        local cmd = string.lower(wx_msg.content)
        if cmd == 'sj' then
            data = cmd
            --data = 
        elseif cmd == 'xh' then
            data = models.random_joke()
            --
        elseif cmd == 'mk' then
            data = cmd
            --
        else
            data = _help()
        end
    elseif string.sub(wx_msg.content, 1, 1) == '#' then
        data = _help()
        --
    else
        data = _help()
    end

    return _packet_msg(wx_msg, data)
end

return _M
