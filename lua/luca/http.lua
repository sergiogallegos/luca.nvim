local M = {}

-- HTTP client for making API requests
-- Uses plenary.nvim if available, falls back to curl

local has_plenary, plenary = pcall(require, "plenary.curl")

function M.stream_request(url, headers, body, on_chunk, on_complete, is_ollama)
  is_ollama = is_ollama or false
  
  -- For Ollama, use curl directly as it handles streaming better
  -- Plenary.curl streaming might not work well with Ollama's format
  if is_ollama then
    -- Use curl for Ollama (more reliable streaming)
    local cmd
    local temp_file = nil
    
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- Windows: Use temp file to avoid JSON escaping issues
      temp_file = vim.fn.tempname() .. ".json"
      local file = io.open(temp_file, "w")
      if file then
        file:write(body)
        file:close()
        cmd = string.format(
          'curl -s -N -X POST "%s" -H "Content-Type: application/json" -d "@%s"',
          url,
          temp_file:gsub("\\", "/")
        )
      else
        vim.notify("Failed to create temp file for Ollama request", vim.log.levels.ERROR)
        return
      end
    else
      -- Unix: Use single quotes to avoid escaping issues
      cmd = string.format(
        "curl -s -N -X POST '%s' -H 'Content-Type: application/json' -d '%s'",
        url,
        body:gsub("'", "'\\''")
      )
    end
    
    local full_response = ""
    local handle = io.popen(cmd)
    
    if not handle then
      vim.notify("Failed to connect to Ollama. Is it running?", vim.log.levels.ERROR)
      if temp_file then
        os.remove(temp_file)
      end
      return
    end
    
    for line in handle:lines() do
      if line and line ~= "" then
        local ok, data = pcall(vim.json.decode, line)
        if ok and data then
          if data.message and data.message.content then
            local content = data.message.content
            full_response = full_response .. content
            if on_chunk then
              vim.schedule(function()
                on_chunk(content)
              end)
            end
          end
          if data.done then
            break
          end
        end
      end
    end
    
    handle:close()
    
    -- Clean up temp file
    if temp_file then
      os.remove(temp_file)
    end
    
    if on_complete then
      vim.schedule(function()
        on_complete(full_response)
      end)
    end
    return
  end
  
  -- For other providers, use plenary if available
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
          -- Parse SSE format (OpenAI format)
          for line in chunk:gmatch("[^\r\n]+") do
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
    -- Build curl command (handle Ollama without auth header)
    local auth_header = ""
    if headers["Authorization"] then
      local auth_token = headers["Authorization"]:match("Bearer (.+)")
      if auth_token then
        if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
          auth_header = string.format('-H "Authorization: Bearer %s"', auth_token)
        else
          auth_header = string.format("-H 'Authorization: Bearer %s'", auth_token)
        end
      end
    end
    
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- Windows curl command
      local body_escaped = body:gsub('"', '\\"')
      if auth_header ~= "" then
        cmd = string.format(
          'curl -s -N -X POST "%s" -H "Content-Type: application/json" %s -d "%s"',
          url,
          auth_header,
          body_escaped
        )
      else
        cmd = string.format(
          'curl -s -N -X POST "%s" -H "Content-Type: application/json" -d "%s"',
          url,
          body_escaped
        )
      end
    else
      -- Unix curl command
      if auth_header ~= "" then
        cmd = string.format(
          "curl -s -N -X POST '%s' -H 'Content-Type: application/json' %s -d '%s'",
          url,
          auth_header,
          body:gsub("'", "'\\''")
        )
      else
        cmd = string.format(
          "curl -s -N -X POST '%s' -H 'Content-Type: application/json' -d '%s'",
          url,
          body:gsub("'", "'\\''")
        )
      end
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

