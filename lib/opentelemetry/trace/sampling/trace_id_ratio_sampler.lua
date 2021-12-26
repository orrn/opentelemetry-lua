local result_new = require("opentelemetry.trace.sampling.result").new
local always_on_sampler_new = require("opentelemetry.trace.sampling.always_on_sampler").new

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(fraction)
    if fraction >= 1 then
        return always_on_sampler_new()
    end

    if fraction < 0 then
        fraction = 0
    end

    return setmetatable({
        trace_id_upper_bound = fraction * 0xffffffff,
        description = string.format("TraceIDRatioBased{%d}", fraction)
    }, mt)
end

function _M.should_sample(self, parameters)
    local parent_ctx = parameters.parent_ctx
    local n = 0
    local trace_id = parameters.trace_id
    for i = 1, 8, 2 do
        n = tonumber(string.sub(trace_id, i, i + 1), 16) + (n * (2 ^ 8))
    end

    if n < self.trace_id_upper_bound then
        return result_new(2, parent_ctx.trace_state)
    end

    return result_new(0, parent_ctx.trace_state)
end

function _M.description(self)
    return self.description
end

return _M