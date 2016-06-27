local models = require 'models'

local ok, err = ngx.timer.at(0, models.reload_joke);
