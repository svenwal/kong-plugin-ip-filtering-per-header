local iputils = require "kong.plugins.ip-filtering-per-header.iputils"
local re_find = ngx.re.find

local IpFilteringHandler = {
  PRIORITY = 800,
  VERSION = "1.0.0",
}

function IpFilteringHandler:access(conf)
  local header_value = kong.request.get_header(conf.header_name)
  kong.log.debug("Header value for " .. conf.header_name .. ": " .. (header_value or "nil"))  
  local source_ip = kong.client.get_forwarded_ip()
  kong.log.debug("Source IP: " .. (source_ip or "nil"))

  if not conf.filters or #conf.filters == 0 then
    kong.log.debug("No filters configured, denying all requests")
    return kong.response.exit(conf.error_code, { message = conf.error_message })
  else
    for _, filter in ipairs(conf.filters) do
        local matched = false

        if not filter.expression or #filter.expression == 0 then
        -- empty expression is a catch-all
        matched = true
        else
        for _, pattern in ipairs(filter.expression) do
            if header_value and re_find(header_value, pattern, "jo") then
            kong.log.debug("Header value '" .. header_value .. "' matched pattern '" .. pattern .. "'")   
            matched = true
            break
            end
        end
        end

        if matched then
        if filter.ip_ranges_allowed and #filter.ip_ranges_allowed > 0 then
            local parsed_cidrs = iputils.parse_cidrs(filter.ip_ranges_allowed)
            if iputils.ip_in_cidrs(source_ip, parsed_cidrs) then
            return
            end
        end
        kong.log.debug("IP " .. (source_ip or "nil") .. " is not allowed for header value '" .. (header_value or "nil") .. "'")
        return kong.response.exit(conf.error_code, { message = conf.error_message })
        end
    end
  end
  -- default is to not allow if no filters matched
  kong.log.debug("No filters matched for IP " .. (source_ip or "nil") .. " and header value '" .. (header_value or "nil") .. "'")
  return kong.response.exit(conf.error_code, { message = conf.error_message })
end

return IpFilteringHandler