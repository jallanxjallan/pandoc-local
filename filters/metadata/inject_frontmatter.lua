-- Generic AutoScribe frontmatter injection.
--
-- Runtime defaults may provide a map under `autoscribe-frontmatter`:
--
-- metadata:
--   autoscribe-frontmatter:
--     slug: cnt.example
--     status: draft
--     producer: ai
--
-- Each entry is merged into the document metadata. Existing keys are preserved
-- unless explicitly overridden by the injected map. The private
-- `autoscribe-frontmatter` key is removed before the document is written.
--
-- Frontmatter serialization remains the writer's responsibility. For Markdown,
-- use a writer/defaults configuration that enables yaml_metadata_block and
-- standalone output.

local FRONTMATTER_KEY = "autoscribe-frontmatter"

local function fail(message)
  error("inject_frontmatter.lua: " .. message)
end

function Pandoc(doc)
  local injected = doc.meta[FRONTMATTER_KEY]

  if injected == nil then
    return doc
  end

  if type(injected) ~= "table" then
    fail("metadata field '" .. FRONTMATTER_KEY .. "' must be a map")
  end

  -- Never leak the private transport key into emitted frontmatter.
  doc.meta[FRONTMATTER_KEY] = nil

  for key, value in pairs(injected) do
    local name = tostring(key)

    if name == "" then
      fail("frontmatter keys must not be empty")
    end

    if name == FRONTMATTER_KEY then
      fail("frontmatter must not recursively define '" .. FRONTMATTER_KEY .. "'")
    end

    doc.meta[name] = value
  end

  return doc
end
