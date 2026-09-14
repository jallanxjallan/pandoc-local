-- AutoScribe dispatch emitter.
--
-- Document semantics live here, not in Rust. Runtime facts are injected by
-- the per-job defaults file as autoscribe-* metadata.

local stringify = pandoc.utils.stringify

local function fail(message)
  error("autoscribe dispatch: " .. message, 0)
end

local function meta_text(meta, key, required)
  local value = meta[key]
  if value == nil then
    if required then fail("missing metadata: " .. key) end
    return nil
  end
  local text = stringify(value)
  if text == "" then
    if required then fail("empty metadata: " .. key) end
    return nil
  end
  return text
end

local function collect_assets(doc)
  local assets = {}
  local seen = {}
  doc:walk({
    Image = function(image)
      local source = image.src
      if source and source ~= "" and not seen[source] then
        seen[source] = true
        assets[#assets + 1] = source
      end
      return image
    end,
  })
  return assets
end

local function body_markdown(doc)
  local body = pandoc.Pandoc(doc.blocks, pandoc.Meta({}))
  local text = pandoc.write(body, "markdown")
  return text:gsub("%s+$", "")
end

function Pandoc(doc)
  local slug = meta_text(doc.meta, "slug", true)
  local status = meta_text(doc.meta, "status", true)
  local stage = meta_text(doc.meta, "stage", false)
  local plan = meta_text(doc.meta, "autoscribe-plan", true)
  local source_kind = meta_text(doc.meta, "autoscribe-source-kind", true)
  local source_path = meta_text(doc.meta, "autoscribe-source-path", true)
  local response_action = meta_text(doc.meta, "autoscribe-response-action", true)

  if status ~= "ai-process" then
    fail(source_path .. ": status must be ai-process")
  end
  if source_kind ~= "vault" then
    fail(source_path .. ": dispatch source kind must be vault")
  end
  local allowed_actions = {
    writeback = true,
    writenew = true,
    export = true,
    none = true,
  }
  if not allowed_actions[response_action] then
    fail(source_path .. ": invalid response action: " .. response_action)
  end

  local source = {
    kind = source_kind,
    path = source_path,
    status = status,
  }
  if stage then source.stage = stage end

  local call = {
    type = "call",
    identity = slug,
    content = body_markdown(doc),
    plan = plan,
    extra = {
      source = source,
      response = { action = response_action },
      assets = collect_assets(doc),
      context = {},
    },
  }

  io.stdout:write(pandoc.json.encode(call), "\n")
  return pandoc.Pandoc({}, pandoc.Meta({}))
end
