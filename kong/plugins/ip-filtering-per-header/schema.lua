local typedefs = require "kong.db.schema.typedefs"

return {
  name = "ip-filtering-per-header",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { header_name = { type = "string", required = true } },
          { error_message = { type = "string", required = true, default = "This IP address is not allowed to call this endpoint" } },
          { error_code = { type = "integer", required = true, default = 403 } },
          { filters = {
              type = "array",
              elements = {
                type = "record",
                fields = {
                  { expression = {
                      type = "array",
                      elements = { type = "string" },
                      required = false,
                  }},
                  { ip_ranges_allowed = {
                      type = "array",
                      elements = typedefs.cidr_v4,
                      required = false,
                  }},
                },
              },
          }},
        },
    }},
  },
  entity_checks = {},
}