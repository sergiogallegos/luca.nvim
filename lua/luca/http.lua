local M = {}

-- HTTP client for making API requests
-- Uses plenary.nvim if available, falls back to curl

local has_plenary, plenary = pcall(require, "plenary.curl")

function M.stream_request(url, headers, body, on_chunk, on_complete, is_ollama)
  is_ollama = is_ollama or false
  
  if has_plenary then
    -- Use plenary for better async support
    local full_response = ""
    
    plenary.request({
      url = url,
      method = "POST",
      headers = headers,
      body = body,
      stream = function(chunk)
        if chunk then
          -- Parse SSE format (different for Ollama vs OpenAI)
          for line in chunk:gmatch("[^\r\n]+") do
            if is_ollama then
              -- Ollama format: plain JSON lines
              local ok, data = pcall(vim.json.decode, line)
              if ok and data.message and data.message.content then
                local content = data.message.content
                full_response = full_response .. content
                if on_chunk then
                  on_chunk(content)
                end
              end
              if ok and data.done then
                if on_complete then
                  on_complete(full_response)
                end
                return
              end
            else
              -- OpenAI format: "data: {...}"
              if line:sub(1, 6) == "data: " then
                local data_str = line:sub(7)
                if data_str == "[DONE]" then
                  if on_complete then
                    on_complete(full_response)
                  end
                  return
                end
                
                local ok, data = pcall(vim.json.decode, data_str)
                if ok and data.choices and data.choices[1] and data.choices[1].delta then
                  local content = data.choices[1].delta.content
                  if content then
                    full_response = full_response .. content
                    if on_chunk then
                      on_chunk(content)
                    end
                  end
                end
              end
            end
          end
        end
      end,
      callback = function(response)
        if on_complete and not full_response:match("%[DONE%]") then
          on_complete(full_response)
        end
      end,
    })
  else
    -- Fallback to curl (Windows compatible)
    local cmd
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- Windows curl command
      local body_escaped = body:gsub('"', '\\"')
      cmd = string.format(
        'curl -s -N -X POST "%s" -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d "%s"',
        url,
        headers["Authorization"]:match("Bearer (.+)"),
        body_escaped
      )
    else
      -- Unix curl command
      cmd = string.format(
        "curl -s -N -X POST '%s' -H 'Content-Type: application/json' -H 'Authorization: Bearer %s' -d '%s'",
        url,
        headers["Authorization"]:match("Bearer (.+)"),
        body:gsub("'", "'\\''")
      )
    end
    
    local full_response = ""
    local handle = io.popen(cmd)
    
    if not handle then
      vim.notify("Failed to connect to API", vim.log.levels.ERROR)
      return
    end
    
    for line in handle:lines() do
      if is_ollama then
        -- Ollama format: plain JSON lines
        local ok, data = pcall(vim.json.decode, line)
        if ok and data.message and data.message.content then
          local content = data.message.content
          full_response = full_response .. content
          if on_chunk then
            on_chunk(content)
          end
        end
        if ok and data.done then
          break
        end
      else
        -- OpenAI format
        if line and line ~= "" and line:sub(1, 6) == "data: " then
          local data_str = line:sub(7)
          if data_str == "[DONE]" then
            break
          end
          
          local ok, data = pcall(vim.json.decode, data_str)
          if ok and data.choices and data.choices[1] and data.choices[1].delta then
            local content = data.choices[1].delta.content
            if content then
              full_response = full_response .. content
              if on_chunk then
                on_chunk(content)
              end
            end
          end
        end
      end
    end
    
    handle:close()
    
    if on_complete then
      on_complete(full_response)
    end
  end
end

return M

