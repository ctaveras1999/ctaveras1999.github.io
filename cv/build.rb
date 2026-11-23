#!/usr/bin/env ruby
# Builds the CV PDF from the website's data, so the CV and the Academic page never drift apart.
#
#   ruby cv/build.rb
#
# Reads   _data/cv.yml, _data/pubs.yml, and cv/template.tex.erb
# Writes  cv/build/cv.tex (generated LaTeX, not committed)
#         media/docs/cv.pdf (the PDF the website links to)
#         _data/cv_build.yml (the date shown as "Last updated" on the Academic page)
# Needs   Ruby (already required by Jekyll) and a LaTeX install with latexmk and pdflatex.

require "yaml"
require "erb"
require "fileutils"
require "date"
require "digest"

ROOT = File.expand_path("..", __dir__)
BUILD = File.join(ROOT, "cv", "build")

data = YAML.load_file(File.join(ROOT, "_data", "cv.yml"))
pubs = YAML.load_file(File.join(ROOT, "_data", "pubs.yml"))

# ---------- Text helpers ----------

# Escape LaTeX special characters in plain text.
def tex(s)
  s.to_s.gsub(/[\\&%$#_{}~^]/) do |c|
    { "\\" => "\\textbackslash{}", "~" => "\\textasciitilde{}", "^" => "\\textasciicircum{}" }[c] || "\\#{c}"
  end
end

# Escape a URL for \href.
def url(s)
  s.to_s.gsub(/[%#]/) { |c| "\\#{c}" }
end

# Convert the small amount of Markdown used in the data files: [text](url), **bold**, *italic*.
# With links: false, a link keeps only its text (for lists where colored links would be distracting).
def md(s, links: true)
  out = +""
  rest = s.to_s
  while (m = rest.match(/\[([^\]]+)\]\(([^)]+)\)/))
    out << inline(m.pre_match)
    out << (links ? "\\href{#{url(m[2])}}{#{inline(m[1])}}" : inline(m[1]))
    rest = m.post_match
  end
  out << inline(rest)
end

def inline(s)
  tex(s).gsub(/\*\*(.+?)\*\*/, '\\textbf{\1}').gsub(/\*(.+?)\*/, '\\textit{\1}')
end

# Bold the CV owner's name in an author list.
def authors(list)
  tex(list).gsub("C.A. Taveras", "\\textbf{C.A. Taveras}")
end

# "Venue Year, pp. X" — or "Venue, Year" when the venue doesn't end with an acronym in parentheses.
def venue(p)
  v = tex(p["venue"])
  s = v.end_with?(")") ? "#{v} #{p['year']}" : "#{v}, #{p['year']}"
  p["pages"] ? "#{s}, pp. #{tex(p['pages'])}" : s
end

# Apply an entry's `cv:` overrides; nil when the entry is marked `cv: false`.
def for_cv(e)
  return nil if e["cv"] == false
  overrides = e["cv"].is_a?(Hash) ? e["cv"] : {}
  merged = e.reject { |k, _| k == "cv" }.merge(overrides)
  # Without CV-specific bullets, a website description (if any) becomes the single bullet.
  merged["bullets"] = overrides["bullets"] || (overrides.empty? && e["desc"] ? [e["desc"]] : [])
  merged["details"] = overrides["details"] || []
  merged
end

def section(data, key) = (data[key] || []).map { |e| for_cv(e) }.compact

# ---------- Data for the template ----------

profile    = data.fetch("profile")
education  = section(data, "education")
awards     = section(data, "awards")
teaching   = section(data, "teaching")
events     = section(data, "events")
employment = section(data, "employment")
service    = section(data, "other")
# Presentations come from the publications they present, newest first (ties keep file order).
presentations = pubs.flat_map { |p| (p["presented"] || []).map { |pr| [p, pr] } }
                    .each_with_index.sort_by { |(_, pr), i| [-pr["year"].to_i, i] }.map(&:first)

# ---------- Render and compile ----------

template = File.read(File.join(ROOT, "cv", "template.tex.erb"))
FileUtils.mkdir_p(BUILD)
File.write(File.join(BUILD, "cv.tex"), ERB.new(template, trim_mode: "-").result(binding))

ok = system("latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error", "-quiet", "cv.tex",
            chdir: BUILD, out: File::NULL)
abort "LaTeX failed; see cv/build/cv.log" unless ok

pdf = File.join(ROOT, "media", "docs", "cv.pdf")
FileUtils.cp(File.join(BUILD, "cv.pdf"), pdf)

# Preview image of page 1 for the Academic page (needs pdftoppm, part of poppler).
preview = File.join(ROOT, "media", "docs", "cv-preview")
system("pdftoppm", "-f", "1", "-l", "1", "-singlefile", "-jpeg", "-jpegopt", "quality=85",
       "-scale-to-x", "400", "-scale-to-y", "-1", pdf, preview) or abort "pdftoppm failed"

pages = `pdfinfo "#{pdf}"`[/^Pages:\s+(\d+)/, 1].to_i
updated = Date.today.strftime("%B %-d, %Y")
# Changes whenever the PDF's contents change; added to the PDF and preview links so browsers
# never show a stale cached copy.
version = Digest::SHA256.file(pdf).hexdigest[0, 10]
File.write(File.join(ROOT, "_data", "cv_build.yml"), <<~YAML)
  # Written by cv/build.rb: when media/docs/cv.pdf was last generated, its page count, and a
  # version tag for cache-busting links.
  updated: "#{updated}"
  pages: #{pages}
  version: "#{version}"
YAML
puts "Built media/docs/cv.pdf (#{pages} pages, #{updated}) and media/docs/cv-preview.jpg"
