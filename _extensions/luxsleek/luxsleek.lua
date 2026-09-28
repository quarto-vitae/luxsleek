--[[
  Render Markdown headings as LuxSleek section headings.

  Upstream (LuxSleek-CV 1.1) names its two heading commands \headleft (a small
  heading inside the tinted sidebar, filled from the `sidebar:` front matter --
  see luxsleek-preamble.tex) and \headright (the large coloured heading that
  opens a section in the white main column, e.g. Work Experience). Neither is
  called \section or \subsection.

  This template still maps `#`/`##` onto \cvsection/\cvsubsection rather than
  onto \headright/\headleft directly, matching the names awesome-cv.lua and
  latexcv.lua use for the same job in the other quarto-vitae templates. A
  document's headings are the one thing every template must agree on the
  meaning of, since the whole point of the shared entries contract is that a
  CV written for one template renders under another just by changing
  `format:` -- so the *filter's* vocabulary is kept uniform across the org even
  where upstream's own macro names differ. \cvsection expands to \headright
  (defined in luxsleek.tex); \headleft is never reached from a heading at all,
  only from the sidebar loop, so it needs no entry here.

  Only levels 1 and 2 are remapped: upstream draws no third level, so level 3
  and below fall through to article's own \subsubsection.
]]

local function raw(s)
  return pandoc.RawInline("latex", s)
end

local function heading_command(level)
  if level == 1 then
    return "\\cvsection"
  elseif level == 2 then
    return "\\cvsubsection"
  end
end

local function rewrite_header(el)
  local cmd = heading_command(el.level)
  if not cmd then
    return nil
  end

  -- Built around the heading's inlines rather than stringified, so emphasis,
  -- links and inline code in a heading survive.
  local inlines = pandoc.List({ raw(cmd .. "{") })
  inlines:extend(el.content)
  inlines:insert(raw("}"))

  -- \cvsection/\cvsubsection issue \phantomsection (see luxsleek.tex), so a
  -- \label placed right after one still resolves to the right page for \ref
  -- and for cross-references such as @sec-education.
  if el.identifier and el.identifier ~= "" then
    inlines:insert(raw("\\label{" .. el.identifier .. "}"))
  end

  return pandoc.Plain(inlines)
end

-- The whole document is walked from here rather than from a top-level Header
-- function so this only ever runs for LaTeX output, matching the other
-- templates' filters.
function Pandoc(doc)
  if not FORMAT:match("latex") then
    return nil
  end
  return doc:walk({ Header = rewrite_header })
end
