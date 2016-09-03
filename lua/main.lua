
local ngx_var = ngx.var
local uri = ngx_var.uri
local method = ngx.req.get_method()
local model = require 'models'
local cjson = require 'cjson'

if uri == '/wx/' then
    local wx = require 'wechat'
    if method == 'GET' then
        local res = wx.check_signature()
        ngx.log(ngx.INFO, 'res:', res)
        ngx.say(res)
    elseif method == 'POST' then
        ngx.req.read_body()
        local data = ngx.req.get_body_data()
        local res = wx.process_msg(data)
        ngx.log(ngx.INFO, 'res:', res)
        ngx.say(res)
    else
        ngx.say('not support http method:'..method)
    end
elseif uri == '/joke/' then
    local res = model.random_joke()
    ngx.say(res)
elseif uri == '/mark/' then
    --local res = model.add_mark('fish', 'test', '你好')
    local res = model.get_marks('olM6ms0pCy7zQPSZbkmhalGYEe3o')
    res = cjson.encode(res)
    ngx.say(res)
elseif uri == '/test/' then
	local sampleJson = [[{"key":"aa-\\d"}]]
	--res = cjson.encode('')
	local res = cjson.decode(sampleJson)
	ngx.say(res['key'])
else
    ngx.say('hello, openresty')
end
