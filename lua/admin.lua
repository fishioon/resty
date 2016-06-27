
local model = require 'models'

local res = model.reload_joke()
ngx.say('jokes count:' .. res)
