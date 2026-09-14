local pandoc = require "pandoc"

-- Strip YAML frontmatter from an included Markdown file.
local function strip_frontmatter(content)
  if content:match("^%s*%-%-%-") then
    content = content:gsub(
      "^%s*%-%-%-[\r\n](.-)[\r\n]%-%-%-[\r\n]?",
      "",
      1
    )
  end

  return content
end


local function has_class(el, wanted)
  for _, class in ipairs(el.classes) do
    if class == wanted then
      return true
    end
  end

  return false
end


local function load_markdown(path)
  local fh, err = io.open(path, "r")

  if not fh then
    error(
      "autoscribe include: cannot open "
      .. tostring(path)
      .. ": "
      .. tostring(err)
    )
  end

  local content = fh:read("*a")
  fh:close()

  content = strip_frontmatter(content)

  local doc = pandoc.read(content, "markdown")

  return doc.blocks
end


function Div(el)
  -- Ignore every Div except our compositor-generated include marker.
  if not has_class(el, "autoscribe-include") then
    return nil
  end

  local path = el.attributes["path"]

  if not path or path == "" then
    error(
      "autoscribe include: missing path attribute"
    )
  end

  -- Replace ONLY the inner include Div with the blocks
  -- parsed from the linked Markdown file.
  --
  -- If this Div sits inside:
  --
  --   ::: {.sidebar}
  --   ::: {.autoscribe-include path="..."}
  --   :::
  --   :::
  --
  -- the outer .sidebar Div therefore survives and now
  -- contains the complete AST of the linked document.
  return load_markdown(path)
end