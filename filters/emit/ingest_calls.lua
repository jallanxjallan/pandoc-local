local stringify = pandoc.utils.stringify

local function meta_string(meta, key)
  local value = meta[key]
  if value == nil then
    return nil
  end
  local text = stringify(value)
  if text == nil or text == "" then
    return nil
  end
  return text
end

local function markdown_content(blocks)
  local text = pandoc.write(pandoc.Pandoc(blocks, pandoc.Meta({})), "markdown")
  return (text:gsub("%s+$", ""))
end

function Pandoc(doc)
  local plan = assert(meta_string(doc.meta, "autoscribe-plan"), "missing autoscribe-plan")
  local identity = assert(
    meta_string(doc.meta, "autoscribe-record-identity"),
    "missing autoscribe-record-identity"
  )
  local source_kind = assert(
    meta_string(doc.meta, "autoscribe-source-kind"),
    "missing autoscribe-source-kind"
  )
  local source_name = assert(
    meta_string(doc.meta, "autoscribe-source-name"),
    "missing autoscribe-source-name"
  )
  local source_format = assert(
    meta_string(doc.meta, "autoscribe-source-format"),
    "missing autoscribe-source-format"
  )
  local response_action = assert(
    meta_string(doc.meta, "autoscribe-response-action"),
    "missing autoscribe-response-action"
  )

  local record = {
    type = "call",
    identity = identity,
    content = markdown_content(doc.blocks),
    plan = plan,
    extra = {
      source = {
        kind = source_kind,
        name = source_name,
        format = source_format,
      },
      response = { action = response_action },
      assets = {},
      context = {},
    },
  }

  io.stdout:write(pandoc.json.encode(record) .. "\n")
  return pandoc.Pandoc({}, pandoc.Meta({}))
end
