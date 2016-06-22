
local ngx_var = ngx.var
local uri = ngx_var.uri
local method = ngx.req.get_method()

if uri == '/wx/' then
    local wx = require 'wechat'
    if method == 'GET' then
        local res = wx.check_signature()
        ngx.log(ngx.INFO, "res:", res)
        ngx.say(res)
    elseif method == 'POST' then
        ngx.req.read_body()
        local data = ngx.req.get_body_data()
        local res = wx.process_msg(data)
        ngx.log(ngx.INFO, "res:", res)
        ngx.say(res)
    else
        ngx.say('not support http method:'..method)
    end
else
    ngx.say(method..': "hello, world"')
end
