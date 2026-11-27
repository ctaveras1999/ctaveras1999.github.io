# Timelines: a page with `timeline: <name>` in its front matter has its events laid out on a
# vertical timeline (styles: "Timeline" in _sass/retro.sass), newest first, with a divider for
# each year. Each event is a ### heading followed by a line of attributes, then Markdown:
#
#   ### Riemann (No Longer) Hypothesis?
#   {: date="2026-11-20" type="Result"}
#
#   A short summary, always shown.
#
#   <!-- more -->
#   The full write-up, folded under "Read more" (leave out the marker to show everything).
#
# Attributes:
#   date     YYYY-MM-DD (required)
#   type     optional tag: Result, Statement, Reaction, Event, Release, ...
#   id       optional link name, e.g. id="alpoge-grh" -> /math/mathai/timeline/#alpoge-grh.
#            Without it, an event's link is its date (#2026-11-20), or, when several events
#            share a date, the date and title (#2026-11-20-riemann-hypothesis-theorem).
#   follows  optional id (or date, if only one event has it) of an earlier event this one
#            follows up; drawn as a smaller hollow marker with a link back
#   time     optional HH:MM, only to order events on the same day (latest on top)
# Days are sorted newest first; events on the same day keep the order they're written in (top
# of the file = top of the page) unless every one of them has a `time`. Text before the first
# event stays above the timeline; footnote definitions ([^x]: ...) can go anywhere.
#
# The events are also saved as site.data["timelines"][<name>] (newest first: date, title (plain
# text), title_html (formatted, for link text), type, id, url, follows), e.g. for a "Latest" box.
require "date"
require "cgi"

module Timeline
  EVENT = /^###[ \t]+(.+?)[ \t]*\n\{:\s*([^}]*)\}[ \t]*$/
  FOOTNOTE = /^\[\^[^\]]+\]:.*(?:\n(?: {4}|\t).*)*/
  MORE = /^<!--\s*more\s*-->[ \t]*$/

  def self.attrs(text)
    text.scan(/([\w-]+)="([^"]*)"/).to_h
  end

  def self.slug(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")

  def self.short_date(d) = d.strftime("%b %-d")

  # A title as link text: footnote markers ([^x]) dropped, the rest of its Markdown
  # (~~strikethrough~~, *emphasis*, `code`, ...) formatted, and links unwrapped (no links in links)
  def self.title_html(site, title)
    md = site.find_converter_instance(Jekyll::Converters::Markdown)
    html = md.convert(title.gsub(/\[\^[^\]]+\]/, "")).strip.sub(%r{\A<p>(.*)</p>\z}m, '\1')
    html.gsub(%r{</?a\b[^>]*>}, "").strip
  end

  def self.title_text(html) = CGI.unescapeHTML(html.gsub(/<[^>]+>/, "")).strip

  def self.process(site, page)
    name = page.data["timeline"].to_s
    text = page.content
    footnotes = text.scan(FOOTNOTE)
    text = text.gsub(FOOTNOTE, "")
    starts = text.enum_for(:scan, EVENT).map { Regexp.last_match.begin(0) }
    return if starts.empty?
    intro = text[0...starts.first]
    chunks = starts.each_with_index.map { |s, i| text[s...(starts[i + 1] || text.length)] }

    events = chunks.each_with_index.map do |chunk, index|
      m = chunk.match(EVENT)
      a = attrs(m[2])
      fail_on = ->(msg) { raise Jekyll::Errors::FatalException, "#{page.path}: the event \"#{m[1]}\" #{msg}" }
      date = begin
        Date.iso8601(a["date"].to_s)
      rescue ArgumentError
        fail_on.call("needs date=\"YYYY-MM-DD\" (got #{a["date"].inspect})")
      end
      time = a["time"]
      fail_on.call("has time=\"#{time}\"; use HH:MM, e.g. time=\"14:30\"") if time && time !~ /\A\d{1,2}:\d{2}\z/
      body = chunk[m.end(0)..].strip
      summary, more = body.split(MORE, 2).map(&:strip)
      { title: m[1], date: date, time: time && format("%05s", time).tr(" ", "0"), type: a["type"],
        follows: a["follows"], id: a["id"], index: index, summary: summary, more: more }
    end

    # Link names: the id if given, else the date (plus the title when the date is shared)
    by_date = events.group_by { |e| e[:date] }
    events.each do |e|
      e[:id] ||= by_date[e[:date]].size == 1 ? e[:date].iso8601 : "#{e[:date].iso8601}-#{slug(e[:title].gsub(/~~.*?~~/, ""))}"
    end
    events.group_by { |e| e[:id] }.each do |id, list|
      next if list.size == 1
      raise Jekyll::Errors::FatalException,
            "#{page.path}: #{list.map { |e| "\"#{e[:title]}\"" }.join(" and ")} have the same link name ##{id}; give one an id=\"...\""
    end
    # A follow-up names its event by id, or by date when only one event has that date
    events.each do |e|
      next unless e[:follows]
      target = events.find { |x| x[:id] == e[:follows] }
      target ||= (same = events.select { |x| x[:date].iso8601 == e[:follows] }).size == 1 ? same.first : nil
      next e[:follows_event] = target if target
      ids = (same || []).map { |x| x[:id] }
      raise Jekyll::Errors::FatalException,
            "#{page.path}: the event \"#{e[:title]}\" has follows=\"#{e[:follows]}\", " +
            (ids.size > 1 ? "but several events have that date; use one of their ids: #{ids.join(", ")}" : "but no event has that id or date")
    end

    # Newest day first; within a day, by time if every event has one, else in file order
    events = by_date.keys.sort.reverse.flat_map do |d|
      day = by_date[d]
      day.all? { |e| e[:time] } ? day.sort_by { |e| [e[:time], -e[:index]] }.reverse : day.sort_by { |e| e[:index] }
    end

    out = [intro.rstrip, "", %(<div class="timeline">)]
    if (latest = events.first)
      out << %(<p class="tl-now"><span class="tl-now-label">Now</span><span class="tl-now-text">Last entry #{latest[:date].strftime("%B %-d, %Y")}</span></p>)
    end
    year = nil
    events.each do |e|
      if e[:date].year != year
        year = e[:date].year
        out << %(<h2 class="tl-year" id="year-#{year}"><span>#{year}</span></h2>)
      end
      classes = ["tl-event"]
      classes << "tl-type-#{slug(e[:type])}" if e[:type]
      classes << "tl-followup" if e[:follows]
      out << %(<section class="#{classes.join(" ")}" id="#{e[:id]}">)
      out << %(<div class="tl-date"><a href="##{e[:id]}"><time datetime="#{e[:date].iso8601}">#{short_date(e[:date])}</time></a>) +
             (e[:type] ? %(<span class="tl-type">#{CGI.escapeHTML(e[:type])}</span>) : "") + "</div>"
      out << %(<div class="tl-body" markdown="1">)
      out << ""
      out << "### #{e[:title]}"
      out << "{: .tl-title}"
      out << ""
      if (target = e[:follows_event])
        if target
          out << %(<p class="tl-follows">Follow-up to <a href="##{target[:id]}">#{title_html(site, target[:title])}</a> (#{short_date(target[:date])})</p>)
          out << ""
        end
      end
      out << e[:summary].to_s
      if e[:more] && !e[:more].empty?
        out << "" << %(<details class="tl-more" markdown="1">) << "<summary>Read more</summary>" << "" << e[:more] << "" << "</details>"
      end
      out << "" << "</div>" << "</section>" << ""
    end
    out << "</div>" << ""
    out.concat(footnotes.map(&:strip))
    page.content = out.join("\n") + "\n"

    base = site.config["baseurl"].to_s + page.url
    (site.data["timelines"] ||= {})[name] = events.map do |e|
      html = title_html(site, e[:title])
      { "date" => e[:date].iso8601, "title" => title_text(html), "title_html" => html, "type" => e[:type], "id" => e[:id],
        "url" => "#{base}##{e[:id]}", "follows" => e[:follows_event] && e[:follows_event][:id] }
    end
  end

  Jekyll::Hooks.register :site, :post_read do |site|
    site.pages.each { |p| process(site, p) if p.data["timeline"] }
  end
end
