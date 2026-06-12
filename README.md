# ip-filtering-per-header

A Kong Gateway plugin that restricts access based on the client's source IP address, conditional on the value of a specified request header. This allows different IP allowlists to be enforced depending on which application or tenant is identified by a header value.

## How it works

For each incoming request the plugin:

1. Reads the value of the configured header (e.g. `X-Consumer-ID`, `X-Api-Key`, …).
2. Iterates through the configured **filters** in order.
3. For each filter, checks whether the header value matches any of the regular expressions in `expression`. A filter with an empty `expression` list acts as a **catch-all** and always matches.
4. On a match, checks whether the client's source IP falls within any of the CIDRs / IPs in `ip_ranges_allowed`.
   - If the IP is allowed → the request proceeds.
   - If the IP is **not** allowed → the request is rejected with the configured error code and message.
5. If no filter matches, the request is denied.

Filters are evaluated in order and evaluation stops at the **first matching filter**.

## Configuration

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `header_name` | string | yes | — | Name of the request header to inspect. |
| `error_code` | integer | yes | `403` | HTTP status code returned when the IP is not allowed. |
| `error_message` | string | yes | `This IP address is not allowed to call this endpoint` | Message body returned when the IP is not allowed. |
| `filters` | array | yes | — | List of filter objects (see below). |

### Filter object

| Field | Type | Required | Description |
|---|---|---|---|
| `expression` | array of strings | no | Regular expressions matched against the header value. An empty array is a catch-all. |
| `ip_ranges_allowed` | array of strings | yes | IPv4 addresses or CIDR ranges (e.g. `192.168.0.0/24`) that are allowed when the expression matches. |

> **Regex matching** Note: anchor your expressions with `^` and `$` if you need a full-string match (e.g. `^test$`).

## Installation

1. Copy `handler.lua`, `schema.lua`, and `iputils.lua` into:
   ```
   kong/plugins/ip-filtering-per-header/
   ```
2. Add the plugin to Kong's plugin list in `kong.conf`:
   ```
   plugins = bundled,ip-filtering-per-header
   ```
3. Restart Kong.

## Example configuration

The example below allows:
- Requests with a `test-header` matching `test` only from the `192.168.0.0/24` subnet or `127.0.0.1`.
- Requests with a `test-header` matching a 1–3 digit value composed of digits 0–8 only from `123.228.65.115`.
- All other header values are not restricted (no catch-all filter is defined).

```yaml
plugins:
  - name: ip-filtering-per-header
    config:
      header_name: test-header
      error_code: 403
      error_message: This IP address is not allowed to call this endpoint
      filters:
        - expression:
            - '^test$'
          ip_ranges_allowed:
            - 192.168.0.0/24
            - 127.0.0.1
        - expression:
            - '^[0-8]{1,3}$'
          ip_ranges_allowed:
            - 123.228.65.115
```


## Notes

- Source IP is resolved via `kong.client.get_forwarded_ip()`, which respects trusted proxy headers (e.g. `X-Forwarded-For`) based on your Kong proxy settings.
- Only IPv4 addresses and CIDR ranges are supported.
- The plugin can be applied to a consumer, consumer_group, route, service, or globally.
