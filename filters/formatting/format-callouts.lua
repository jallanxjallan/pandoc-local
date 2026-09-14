local pandoc = require "pandoc"


local ENTITY_CLASSES = {
  sidebar = true,
  epigraph = true,
  boxout = true,
  callout = true,
}


local function first_entity_class(classes)
  for _, class in ipairs(classes) do
    if ENTITY_CLASSES[class] then
      return class
    end
  end

  return nil
end


local function title_case(text)
  if not text or text == "" then
    return ""
  end

  return text
    :gsub("^%l", string.upper)
    :gsub("[-_](%l)", function(c)
      return " " .. string.upper(c)
    end)
end


local function make_labeled_callout(el, entity_type, label)
  local blocks = {}

  label = label or ""

  if label == "" then
    label = title_case(entity_type)
  end

  -- Insert a horizontal rule above the label.
  table.insert(blocks, pandoc.HorizontalRule())

  -- Put the label above the complete callout contents.
  table.insert(
    blocks,
    pandoc.Para({
      pandoc.Strong({
        pandoc.Str(label)
      })
    })
  )

  -- Preserve every existing AST block underneath it.
  for _, block in ipairs(el.content) do
    table.insert(blocks, block)
  end

  -- Insert a horizontal rule before the end of the div.
  table.insert(blocks, pandoc.HorizontalRule())

  return pandoc.Div(
    blocks,
    pandoc.Attr(
      el.identifier or "",
      { "callout", entity_type },
      el.attributes or {}
    )
  )
end


function Div(el)
  local entity_type =
    first_entity_class(el.classes)

  if not entity_type then
    return nil
  end

  local label =
    el.attributes["label"]

  return make_labeled_callout(
    el,
    entity_type,
    label
  )
end


local function extract_obsidian_callout_type(text)
  local t =
    text:match("^%[!([%w%-_]+)%]")

  if t then
    return string.lower(t)
  end

  return nil
end


function BlockQuote(el)
  if #el.content == 0 then
    return nil
  end

  local first = el.content[1]

  if first.t ~= "Para" then
    return nil
  end

  local first_text =
    pandoc.utils.stringify(first)

  local callout_type =
    extract_obsidian_callout_type(first_text)

  if not callout_type then
    return nil
  end

  local blocks = {}

  -- Remove the Obsidian marker from the first paragraph.
  local cleaned =
    first_text:gsub(
      "^%[!([%w%-_]+)%]%s*",
      ""
    )

  -- Insert a horizontal rule above the label.
  table.insert(blocks, pandoc.HorizontalRule())

  -- Generic label above all callouts.
  table.insert(
    blocks,
    pandoc.Para({
      pandoc.Strong({
        pandoc.Str(
          title_case(callout_type)
        )
      })
    })
  )

  if cleaned ~= "" then
    table.insert(
      blocks,
      pandoc.Para({
        pandoc.Str(cleaned)
      })
    )
  end

  -- Preserve the remaining AST blocks.
  for i = 2, #el.content do
    table.insert(
      blocks,
      el.content[i]
    )
  end

  -- Insert a horizontal rule before the end of the div.
  table.insert(blocks, pandoc.HorizontalRule())

  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "callout",
        callout_type
      },
      {}
    )
  )
end