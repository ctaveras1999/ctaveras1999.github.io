#!/usr/bin/env ruby
# Adds an entry to the Math and AI list (_data/mathai.yml), filling in what it can from the link:
# title, date, and source (YouTube channel, site, or arXiv), plus authors for papers.
#
#   ruby scripts/add-link.rb URL --type "Talks & Panels" [--people "A and B"] [--title "..."]
#                                [--source "..."] [--date YYYY-MM-DD] [--dry-run]
#
# The entry goes at the top of its type's group, so "Grouped by type" shows newest additions first.
# Check the result in _data/mathai.yml: titles from web pages sometimes carry extra text
# (e.g. "| Channel name"), and speakers usually need to be added by hand with --people.
# Uses only Ruby's standard library.

require "net/http"
require "uri"
require "json"
require "cgi"
require "optparse"

DATA = File.expand_path("../_data/mathai.yml", __dir__)
TYPES = ["Blogs", "Blog Posts", "Essays & Articles", "Declarations & Statements", "Classics",
         "Talks & Panels", "Recent Results", "Using AI for Research", "Education",
         "Interview Series", "SAIR", "Candid Reactions"].freeze

opts = {}
parser = OptionParser.new do |o|
  o.banner = "Usage: ruby scripts/add-link.rb URL --type TYPE [options]"
  o.on("--type TYPE", "One of: #{TYPES.join(', ')}") { |v| opts[:type] = v }
  o.on("--people NAMES", "Authors or speakers, e.g. \"Terence Tao and Yu Deng\"") { |v| opts[:people] = v }
  o.on("--title TITLE", "Use this title instead of the fetched one") { |v| opts[:title] = v }
  o.on("--source SOURCE", "Use this source instead of the fetched one") { |v| opts[:source] = v }
  o.on("--date DATE", "YYYY-MM-DD or YYYY, instead of the fetched one") { |v| opts[:date] = v }
  o.on("--dry-run", "Print the entry without changing the file") { opts[:dry] = true }
end
parser.parse!
url = ARGV.shift
abort parser.help unless url && opts[:type]
unless TYPES.include?(opts[:type])
  warn "Note: \"#{opts[:type]}\" is a new type; it will get its own filter chip and group."
end

# ---------- Fetching ----------

def fetch(url, limit = 5)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri, "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) Firefox/140.0",
                                "Accept-Language" => "en-US")
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                        open_timeout: 15, read_timeout: 25) { |h| h.request(req) }
  if res.is_a?(Net::HTTPRedirection) && limit > 0
    return fetch(URI.join(url, res["location"]).to_s, limit - 1)
  end
  res.is_a?(Net::HTTPSuccess) ? res.body.to_s.force_encoding("UTF-8").scrub : ""
rescue StandardError => e
  warn "Couldn't fetch #{url}: #{e.message}"
  ""
end

def meta(html, *names)
  names.each do |n|
    m = html.match(/<meta[^>]+(?:property|name)=["']#{Regexp.escape(n)}["'][^>]+content=["']([^"']*)["']/i) ||
        html.match(/<meta[^>]+content=["']([^"']*)["'][^>]+(?:property|name)=["']#{Regexp.escape(n)}["']/i)
    return CGI.unescapeHTML(m[1]).strip if m && !m[1].strip.empty?
  end
  nil
end

# arXiv titles and names often use TeX accents, e.g. Schr\"odinger.
TEX_ACCENTS = { '"' => "̈", "'" => "́", "`" => "̀", "^" => "̂", "~" => "̃",
                "c" => "̧" }.freeze
def untex(s)
  return s unless s
  s.gsub(/\\([\"'`^~c])\{?\\?([A-Za-z])\}?/) { ($2 + TEX_ACCENTS[$1]).unicode_normalize(:nfc) }
   .gsub(/[{}]/, "")
end

# Author names from a page's structured data (JSON-LD), e.g. "author":{"name":"..."}.
def jsonld_authors(html)
  names = []
  html.scan(%r{<script[^>]+application/ld\+json[^>]*>(.*?)</script>}m).flatten.each do |js|
    data = JSON.parse(js) rescue next
    [data].flatten.each do |d|
      next unless d.is_a?(Hash)
      [d["author"]].flatten.compact.each { |a| names << (a.is_a?(Hash) ? a["name"] : a) }
    end
  end
  names = names.compact.map(&:strip).reject(&:empty?).uniq
  return nil if names.empty?
  names.size > 1 ? "#{names[0..-2].join(', ')} and #{names[-1]}" : names.first
end

def iso_date(s)
  return nil unless s
  m = s.match(/(\d{4})[-\/](\d{2})[-\/](\d{2})/)
  m ? "#{m[1]}-#{m[2]}-#{m[3]}" : nil
end

info = {}
youtube = url.match(%r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|live/))([\w-]{11})})
arxiv = url.match(%r{arxiv\.org/(?:abs|pdf)/(\d{4}\.\d{4,5})})

if youtube
  id = youtube[1]
  url = "https://youtu.be/#{id}?t=0" # canonical form; t=0 starts at the beginning
  o = JSON.parse(fetch("https://www.youtube.com/oembed?format=json&url=https://youtu.be/#{id}")) rescue {}
  info[:title] = o["title"]
  info[:source] = "YouTube: #{o['author_name']}" if o["author_name"]
  info[:date] = iso_date(fetch("https://www.youtube.com/watch?v=#{id}")[/"uploadDate":"([^"]+)"/, 1])
elsif arxiv
  html = fetch("https://arxiv.org/abs/#{arxiv[1]}")
  info[:title] = untex(meta(html, "citation_title"))
  authors = html.scan(/<meta name="citation_author" content="([^"]+)"/).flatten.map do |a|
    last, first = a.split(", ", 2) # arXiv lists "Last, First"
    untex([first, last].compact.join(" "))
  end
  info[:people] = authors.size > 1 ? "#{authors[0..-2].join(', ')} and #{authors[-1]}" : authors.first
  info[:date] = iso_date(meta(html, "citation_date"))
  info[:source] = "arXiv"
else
  html = fetch(url)
  info[:title] = meta(html, "og:title", "twitter:title") ||
                 (CGI.unescapeHTML(html[%r{<title>([^<]*)</title>}i, 1].to_s).strip if html =~ /<title>/i)
  info[:source] = meta(html, "og:site_name")
  info[:people] = jsonld_authors(html) || meta(html, "author", "citation_author")
  info[:people] = nil if info[:people].to_s.start_with?("http") # some sites put a profile URL here
  info[:date] = iso_date(meta(html, "article:published_time", "citation_date", "date") ||
                         html[/"datePublished"\s*:\s*"([^"]+)"/, 1])
  info[:date] ||= iso_date(url[%r{/(\d{4}/\d{2}/\d{2})/}, 1]) # e.g. WordPress URLs
end

# Drop a trailing " | Site name" / " - Site name" that many pages add to their titles.
if info[:title] && info[:source]
  info[:title] = info[:title].sub(/\s+[|\-–—]\s+#{Regexp.escape(info[:source].sub(/^YouTube: /, ''))}\s*\z/, "")
end

entry = {
  name: opts[:title] || info[:title],
  url: url,
  people: opts[:people] || info[:people],
  source: opts[:source] || info[:source],
  date: opts[:date] || info[:date],
  topics: [opts[:type]]
}
abort "Couldn't find a title; pass one with --title." if entry[:name].to_s.empty?

# ---------- Writing ----------

q = ->(s) { JSON.generate(s.to_s) } # JSON strings are valid YAML strings
lines = ["- name: #{q[entry[:name]]}", "  url: #{q[entry[:url]]}"]
lines << (entry[:people] ? "  people: #{q[entry[:people]]}" : "  # people: \"\"   <- add authors/speakers")
lines << "  source: #{q[entry[:source]]}" if entry[:source]
lines << (entry[:date] ? "  date: #{q[entry[:date]]}" : "  # date: \"YYYY-MM-DD\"   <- add if known")
lines << "  topics: [#{q[opts[:type]]}]"
block = lines.join("\n")

text = File.read(DATA)
if text.include?(%(url: #{q[url]})) || text.include?(%(url: #{q[url.sub(/[?&]t=0$/, '')]}))
  abort "Already in the list: #{url}"
end

puts block
if opts[:dry]
  puts "\n(dry run: _data/mathai.yml not changed)"
  exit
end

header = "# ---------- #{opts[:type]} ----------\n"
if (i = text.index(header))
  i += header.length
  text = text[0...i] + block + "\n" + text[i..]
else
  text = text.rstrip + "\n\n" + header + block + "\n"
end
File.write(DATA, text)
puts "\nAdded to _data/mathai.yml under \"#{opts[:type]}\". Check it, then build the site to preview."
