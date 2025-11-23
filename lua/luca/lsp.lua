local M = {}

-- LSP Integration for AST, symbols, and diagnostics

local function get_lsp_clients()
  local clients = {}
  local active_clients = vim.lsp.get_active_clients()
  for _, client in ipairs(active_clients) do
    table.insert(clients, client)
  end
  return clients
end

function M.get_symbols(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = get_lsp_clients()
  
  if #clients == 0 then
    return {}
  end
  
  local symbols = {}
  local client = clients[1] -- Use first available client
  
  if client.supports_method("textDocument/documentSymbol") then
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
    }
    
    local result = client.request_sync("textDocument/documentSymbol", params, 1000, bufnr)
    
    if result and result.result then
      for _, symbol in ipairs(result.result) do
        table.insert(symbols, {
          name = symbol.name,
          kind = symbol.kind,
          range = symbol.location and symbol.location.range or symbol.range,
          detail = symbol.detail,
        })
      end
    end
  end
  
  return symbols
end

function M.get_diagnostics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.diagnostic.get(bufnr)
end

function M.get_ast_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = get_lsp_clients()
  
  if #clients == 0 then
    return nil
  end
  
  local client = clients[1]
  local ast_info = {
    symbols = M.get_symbols(bufnr),
    diagnostics = M.get_diagnostics(bufnr),
    language = vim.bo[bufnr].filetype,
  }
  
  -- Get type information if available
  if client.supports_method("textDocument/hover") then
    ast_info.has_hover = true
  end
  
  if client.supports_method("textDocument/completion") then
    ast_info.has_completion = true
  end
  
  return ast_info
end

function M.get_context_at_position(bufnr, line, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = get_lsp_clients()
  
  if #clients == 0 then
    return nil
  end
  
  local client = clients[1]
  local context = {
    position = { line = line, character = col },
    symbols = {},
    diagnostics = {},
  }
  
  -- Get symbol at position
  if client.supports_method("textDocument/hover") then
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
      position = { line = line, character = col },
    }
    
    local result = client.request_sync("textDocument/hover", params, 1000, bufnr)
    if result and result.result and result.result.contents then
      context.hover = result.result.contents
    end
  end
  
  -- Get diagnostics at position
  local diags = vim.diagnostic.get(bufnr, { lnum = line })
  context.diagnostics = diags
  
  return context
end

function M.get_type_definitions(bufnr, line, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = get_lsp_clients()
  
  if #clients == 0 then
    return {}
  end
  
  local client = clients[1]
  local types = {}
  
  if client.supports_method("textDocument/typeDefinition") then
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
      position = { line = line, character = col },
    }
    
    local result = client.request_sync("textDocument/typeDefinition", params, 1000, bufnr)
    if result and result.result then
      if result.result.uri then
        table.insert(types, result.result)
      elseif type(result.result) == "table" then
        types = result.result
      end
    end
  end
  
  return types
end

function M.format_lsp_context(ast_info)
  if not ast_info then
    return ""
  end
  
  local parts = {}
  
  if ast_info.language then
    table.insert(parts, "Language: " .. ast_info.language)
  end
  
  if ast_info.symbols and #ast_info.symbols > 0 then
    table.insert(parts, "\nSymbols:")
    for _, symbol in ipairs(ast_info.symbols) do
      table.insert(parts, string.format("  - %s (%s)", symbol.name, vim.lsp.protocol.SymbolKind[symbol.kind] or "unknown"))
    end
  end
  
  if ast_info.diagnostics and #ast_info.diagnostics > 0 then
    table.insert(parts, "\nDiagnostics:")
    for _, diag in ipairs(ast_info.diagnostics) do
      table.insert(parts, string.format("  - [%s] %s", diag.severity, diag.message))
    end
  end
  
  return table.concat(parts, "\n")
end

return M

