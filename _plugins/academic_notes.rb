# Academic notes: theorem-style blocks, automatic numbering, cross-references, "Referenced in"
# lists, and an index of all statements for the math notes in _notes/. Uses the same syntax as
# the Obsidian "Academic Notes" plugin (https://github.com/Kristal-Boltinn/academic-notes), so
# notes work the same in both.
#
# Blocks (Obsidian callouts), optionally followed by a label line:
#
#   > [!def] Continuity
#   > A map is continuous if the inverse image of every open set is open.
#
#   ^def-continuity
#
#   Types: def, thm, lem, prop, cor, claim, example, axiom, assumption, exercise, conjecture,
#   hypothesis (numbered); proof, remark, solution (unnumbered). Long names work too
#   (definition, theorem, ...). Options: [!thm|A.1] manual number, [!thm|*] unnumbered,
#   [!thm]- / [!thm]+ collapsible (folded / open). "> [!proof] [[#^thm-x]]" titles a proof
#   "Proof of Theorem 1.2". Blocks can be nested with extra ">".
#
# Numbering: one shared counter for all numbered blocks, restarting at every "## " heading and
# shown as <section>.<n> (just <n> before the first "## ").
#
# References:
#   [[#^def-continuity]]                same note       -> "Definition 1.2"
#   [[Topology#^thm-tychonoff]]         another note    -> "Theorem 3.1 (Topology)"
#   [[#^def-continuity|continuity]]     custom text
#   [[Topology]]                        link to a note
# A note is named by its file name (without .md) or its title. An unknown or duplicate label
# stops the build with a message saying where it is.
#
# Topic folders: notes can live in folders under _notes/, e.g.
#   _notes/analysis/metric-spaces/metric-spaces.md  -> /math/notes/analysis/metric-spaces/
#   _notes/analysis/metric-spaces/completeness.md   -> /math/notes/analysis/metric-spaces/completeness/
# (a file named like its folder is that folder's main page). The folders are the note's topic
# ("Analysis > Metric Spaces"): folder names become titles (metric-spaces -> Metric Spaces), or
# set names in _data/note_topics.yml (e.g. `pde: PDE`). Moving a note between folders keeps all
# references working, since notes are found by title or file name. If two notes share a name,
# refer to one by its path: [[analysis/metric-spaces/metric-spaces#^def-metric]].
#
# Also produced:
#   - "Referenced in" under each labeled block, linking to every reference to it (any note).
#   - site.data["notes_index"]: every numbered block, for the index on /math/notes/.
#   - site.data["notes_graph"]: nodes (notes and statements) and directed edges ("A refers to B")
#     at both levels, for the Notes Map on /math/notes/graph/ (assets/js/notes-graph.js).
#   Hover previews of references are done in the browser by assets/js/notes.js.
#
# How it works: pass 1 (Note) numbers blocks, turns them into HTML, and records labels and the
# position of every reference; pass 2 (Linker) turns [[...]] into links and fills in the
# "Referenced in" lists; then math is shielded from Markdown (see protect_math).

require "cgi"
require "json"

module AcademicNotes
  TYPES = {
    "def" => "Definition", "definition" => "Definition",
    "thm" => "Theorem", "theorem" => "Theorem",
    "lem" => "Lemma", "lemma" => "Lemma",
    "prop" => "Proposition", "proposition" => "Proposition", "prp" => "Proposition",
    "cor" => "Corollary", "corollary" => "Corollary",
    "claim" => "Claim", "clm" => "Claim",
    "example" => "Example", "ex" => "Example", "exa" => "Example", "exm" => "Example",
    "axiom" => "Axiom", "axm" => "Axiom",
    "assumption" => "Assumption", "asm" => "Assumption",
    "exercise" => "Exercise", "exr" => "Exercise",
    "conjecture" => "Conjecture", "cnj" => "Conjecture",
    "hypothesis" => "Hypothesis", "hyp" => "Hypothesis",
    "proof" => "Proof", "pf" => "Proof",
    "remark" => "Remark", "rem" => "Remark", "rmk" => "Remark",
    "solution" => "Solution", "sol" => "Solution"
  }.freeze
  UNNUMBERED = %w[Proof Remark Solution].freeze
  CALLOUT = /\A\[!(\w+)(?:\|([^\]]*))?\]([+-])?[ \t]*(.*)\z/
  LABEL = /\A\^([A-Za-z0-9-]+)\s*\z/
  SPACED_LABEL = /\A\^\s+([A-Za-z0-9-]+)\s*\z/   # "^ label": accepted, with a warning
  FENCE = /\A\s*(```|~~~)/
  REF = /\[\[([^\]|#]*)#\^([A-Za-z0-9-]+)(?:\|([^\]]+))?\]\]/
  NOTE_LINK = /\[\[([^\]|#^]+)(?:\|([^\]]+))?\]\]/
  BACKREFS_SHOWN = 5   # "Referenced in" lists longer than this start collapsed
  BACKREFS = /\AACADBACKREFS:([A-Za-z0-9-]+)\z/

  class Error < StandardError; end

  # ---------- Math protection ----------
  # Markdown would eat backslashes in math (\{ becomes {, \\ becomes \). Before conversion each
  # formula is swapped for a placeholder; after rendering the original LaTeX is put back.
  MATH = /
    \$\$.+?\$\$                          |   # $$ display $$
    \\begin\{([a-zA-Z]+\*?)\}.+?\\end\{\1\} |   # \begin{env} ... \end{env}
    \\\[.+?\\\]                          |   # \[ display \]
    \\\(.+?\\\)                          |   # \( inline \)
    (?<!\\)\$(?!\$)[^$\n]+?(?<!\\)\$        # $ inline $
  /mx

  def self.protect_math(doc)
    saved = []
    fence = nil
    chunks = doc.content.split(/(^[ \t]*(?:```|~~~).*$)/)   # keep code fences untouched
    doc.content = chunks.map do |chunk|
      if chunk =~ /\A[ \t]*(```|~~~)/
        fence = fence ? nil : $1
        next chunk
      end
      next chunk if fence
      chunk.gsub(MATH) { saved << $&; "ACADMATH#{saved.length - 1}X" }
    end.join
    doc.data["academic_math"] = saved
  end

  def self.restore_math(doc)
    saved = doc.data["academic_math"] or return
    doc.output = doc.output.gsub(/ACADMATH(\d+)X/) { CGI.escapeHTML(saved[$1.to_i]) }
  end

  # Walks lines, skipping code fences; yields the other lines with their index.
  def self.each_text_line(lines)
    fence = nil
    lines.each_with_index do |line, i|
      if fence
        fence = nil if line =~ FENCE && line.strip.start_with?(fence)
        next
      end
      if (m = line.match(FENCE))
        fence = m[1]
        next
      end
      yield line, i
    end
  end

  # ---------- Pass 1: number the blocks, record labels and references, blocks -> HTML ----------
  class Note
    attr_reader :doc, :labels, :blocks, :refs, :nodes

    def initialize(doc)
      @doc = doc
      @labels = {}   # label => { name:, number:, title:, id: }
      @blocks = []   # numbered blocks, in order: { name:, number:, title:, id: }
      @nodes = []    # blocks with an anchor (numbered or labeled), for the Notes Map
      @refs = []     # every [[...#^...]], in document order: { note:, label:, id:, context: }
      @section = 0
      @section_title = nil
      @counter = 0
    end

    def path = doc.relative_path
    def title = doc.data["title"] || doc.basename_without_ext

    def transform!
      doc.content = render(doc.content.split("\n", -1), nil).join("\n")
    end

    private

    # Renders lines (top level, or a block's body with `context` = that block), turning
    # callouts into HTML and recording references.
    def render(lines, context)
      out = []
      i = 0
      fence = nil
      while i < lines.length
        line = lines[i]
        if fence
          fence = nil if line =~ FENCE && line.strip.start_with?(fence)
          out << line
          i += 1
          next
        end
        if (m = line.match(FENCE))
          fence = m[1]
          out << line
          i += 1
          next
        end
        if context.nil? && line.start_with?("## ")
          @section += 1
          @counter = 0
          @section_title = line.sub(/\A##\s+/, "").strip
        end
        stripped = line.sub(/\A>[ \t]?/, "")
        if line.start_with?(">") && (m = stripped.match(CALLOUT)) && TYPES.key?(m[1].downcase)
          body = []
          j = i + 1
          while j < lines.length && lines[j].start_with?(">")
            body << lines[j].sub(/\A>[ \t]?/, "")
            j += 1
          end
          # Optional label: "^id" on the next line, or after one blank line
          label_line = ->(s) { s =~ LABEL || s =~ SPACED_LABEL }
          k = j
          k += 1 if k < lines.length && lines[k].strip.empty? && k + 1 < lines.length && label_line.(lines[k + 1])
          label = nil
          if k < lines.length && (lm = lines[k].match(LABEL))
            label = lm[1]
            j = k + 1
          elsif k < lines.length && (lm = lines[k].match(SPACED_LABEL))
            label = lm[1]
            j = k + 1
            Jekyll.logger.warn "Academic notes:", "#{path}: label \"#{lines[k].strip}\" has a space after ^; " \
                                                  "write ^#{label} (Obsidian needs it without the space)"
          end
          out.concat(block(m[1].downcase, m[2], m[3], m[4].strip, body, label, context))
          i = j
          next
        end
        record_refs(line, context)
        out << line
        i += 1
      end
      out
    end

    # Remembers each reference in a line, with where it sits (the block around it, or the
    # section), for the "Referenced in" lists. Pass 2 gives the links ids in the same order.
    def record_refs(text, context)
      text.scan(REF) do |name, label, _|
        @refs << { note: name, label: label, id: "xref-#{@refs.length + 1}",
                   context: context || { text: @section_title ? "§ #{@section_title}" : "Introduction" } }
      end
    end

    def block(type, meta, fold, title, body, label, outer)
      name = TYPES[type]
      number = nil
      unless UNNUMBERED.include?(name) || %w[* -].include?(meta.to_s.strip) || meta == ""
        if meta.nil? || meta.strip == "auto"
          @counter += 1
          number = @section.positive? ? "#{@section}.#{@counter}" : @counter.to_s
        else
          number = meta.strip
        end
      end
      # Every numbered block gets an anchor (its label, or e.g. "theorem-1-3") for the index
      id = label || (number && "#{name.downcase}-#{number.gsub(/[^A-Za-z0-9]+/, "-")}")
      if label
        raise Error, "duplicate label ^#{label} in #{path}" if @labels.key?(label)
        @labels[label] = { name: name, number: number, title: title, id: id }
      end
      @blocks << { name: name, number: number, title: title, id: id } if number
      @nodes << { name: name, number: number, title: title, id: id } if id

      css = name.downcase
      head = %(<span class="env-name">#{name}#{number ? " #{number}" : ""}</span>)
      proof_of = name == "Proof" && title.match?(/\A\[\[.*\]\]\z/)
      if proof_of
        head = %(<span class="env-name">Proof of #{title}</span>)   # link filled in by pass 2
      elsif !title.empty?
        head += %(<span class="env-title"> · #{title}</span>)
      end
      # What references inside this block are "in", for the "Referenced in" lists
      context =
        if proof_of && (pm = title.match(REF)) then { proof_of: [pm[1], pm[2]] }
        else { text: [name, number].compact.join(" "), id: id }
        end
      # A reference in the block's own title belongs to the block ("Proof of [[...]]" -> "Proof")
      record_refs(title, proof_of ? { text: "Proof" } : context)
      inner = render(body, context)
      back = label ? ["", "ACADBACKREFS:#{label}"] : []
      attrs = %( class="env env-#{css}"#{id ? %( id="#{id}") : ""})
      if fold
        [%(<details#{attrs}#{fold == "+" ? " open" : ""} markdown="1">),
         %(<summary class="env-head" markdown="span">#{head}</summary>), "", *inner, *back, "", "</details>", ""]
      else
        [%(<div#{attrs} markdown="1">),
         %(<div class="env-head" markdown="span">#{head}</div>), "", *inner, *back, "", "</div>", ""]
      end
    end
  end

  # ---------- Pass 2: [[...]] -> links, "Referenced in" lists, index ----------
  class Linker
    def initialize(site, notes)
      @site = site
      @notes = notes
      @by_key = {}
      ambiguous = {}
      notes.each do |n|
        [n.doc.data["note_key"], n.doc.basename_without_ext, n.doc.data["title"]].compact.map(&:downcase).uniq.each do |key|
          if @by_key[key] && @by_key[key] != n
            (ambiguous[key] ||= [@by_key[key]]) << n
          else
            @by_key[key] = n
          end
        end
      end
      @ambiguous = ambiguous
      # backrefs[target note][label] = [{ from:, ref: }]
      @backrefs = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
      notes.each do |from|
        from.refs.each do |r|
          to = target_note(r[:note], from)
          lookup(to, r[:label], from)
          @backrefs[to][r[:label]] << { from: from, ref: r }
        end
      end
    end

    def link!(note)
      count = 0
      lines = note.doc.content.split("\n", -1)
      AcademicNotes.each_text_line(lines) do |line, i|
        if (m = line.match(BACKREFS))
          lines[i] = backrefs_html(note, m[1])
          next
        end
        lines[i] = line.gsub(REF) { count += 1; ref($1, $2, $3, note, "xref-#{count}") }
                       .gsub(NOTE_LINK) { note_link($1, $2, note) }
      end
      note.doc.content = lines.join("\n")
    end

    # The Notes Map: notes and statements as nodes; "A refers to B" edges at the note level
    # (counted) and at the statement level. A reference inside a proof counts as the proved
    # statement referring to it. References outside any statement only count for notes.
    def graph
      key = ->(n) { n.doc.data["note_key"] }
      topic = ->(n) { n.doc.data["topic_path"].join(" › ") }
      nodes = []
      @notes.each do |n|
        nodes << { "id" => "note:#{key[n]}", "kind" => "note", "label" => n.title, "topic" => topic[n], "url" => url(n) }
        n.nodes.each do |b|
          nodes << { "id" => "st:#{key[n]}##{b[:id]}", "kind" => "statement", "type" => b[:name],
                     "label" => [b[:name], b[:number]].compact.join(" "), "title" => b[:title],
                     "note" => "note:#{key[n]}", "noteTitle" => n.title, "topic" => topic[n],
                     "url" => "#{url(n)}##{b[:id]}" }
        end
      end
      note_edges = Hash.new(0)
      statement_edges = {}
      @notes.each do |from|
        from.refs.each do |r|
          to = target_note(r[:note], from)
          target = lookup(to, r[:label], from)
          note_edges[["note:#{key[from]}", "note:#{key[to]}"]] += 1 if to != from
          ctx = r[:context]
          source =
            if ctx[:proof_of]
              pn = target_note(ctx[:proof_of][0], from)
              pl = pn.labels[ctx[:proof_of][1]]
              pl && pl[:id] && "st:#{key[pn]}##{pl[:id]}"
            elsif ctx[:id]
              "st:#{key[from]}##{ctx[:id]}"
            end
          dest = "st:#{key[to]}##{target[:id]}"
          statement_edges[[source, dest]] = true if source && source != dest
        end
      end
      edges = note_edges.map { |(s, d), c| { "source" => s, "target" => d, "kind" => "note", "weight" => c } } +
              statement_edges.keys.map { |s, d| { "source" => s, "target" => d, "kind" => "statement" } }
      { "nodes" => nodes, "edges" => edges }
    end

    # Every numbered block across all notes, in the shape the filterable list expects.
    def index
      @notes.sort_by { |n| [n.doc.data["topic_path"].map(&:downcase), n.title.downcase] }.flat_map do |n|
        n.blocks.map do |b|
          { "name" => [b[:name], b[:number]].compact.join(" ") + (b[:title].empty? ? "" : " · #{b[:title]}"),
            "url" => "#{url(n)}##{b[:id]}", "affiliation" => (n.doc.data["topic_path"] + [n.title]).uniq.join(" › "), "topics" => [b[:name]] }
        end
      end
    end

    private

    def target_note(name, from)
      return from if name.strip.empty?
      key = name.strip.downcase.sub(/\.md\z/, "")
      if (many = @ambiguous[key])
        raise Error, "#{from.path}: \"#{name}\" could be any of #{many.map(&:path).join(", ")}; " \
                     "refer to one by its path, e.g. [[#{many.first.doc.data["note_key"]}#^...]]"
      end
      @by_key[key] or
        raise Error, "#{from.path}: unknown note \"#{name}\" in a [[...]] reference"
    end

    def lookup(to, label, from)
      to.labels[label] or
        raise Error, "#{from.path}: unknown label ^#{label}#{to == from ? "" : " in #{to.path}"}"
    end

    def url(note) = @site.config["baseurl"].to_s + note.doc.url

    def ref_text(to, label, from)
      t = lookup(to, label, from)
      text = [t[:name], t[:number]].compact.join(" ")
      to == from ? text : "#{text} (#{to.title})"
    end

    def ref(name, label, text, from, id)
      to = target_note(name, from)
      t = lookup(to, label, from)
      text ||= ref_text(to, label, from)   # custom text ([[...|text]]) is used as is
      href = to == from ? "##{t[:id]}" : "#{url(to)}##{t[:id]}"
      %(<a class="xref" id="#{id}" href="#{href}">#{text}</a>)
    end

    def note_link(name, text, from)
      to = target_note(name, from)
      %(<a class="xref-note" href="#{url(to)}">#{text || to.title}</a>)
    end

    # "Referenced in: Proof of Theorem 1.3 · Proposition 1.2 (Metric Spaces)"
    def backrefs_html(note, label)
      entries = @backrefs[note][label]
      return "" if entries.empty?
      proofs, others = [], []
      entries.each do |e|
        ctx = e[:ref][:context]
        text =
          if ctx[:proof_of]
            # named relative to this note, so a proof elsewhere gets its note's title
            "Proof of " + ref_text(target_note(ctx[:proof_of][0], e[:from]), ctx[:proof_of][1], note)
          else
            ctx[:text]
          end
        text += " (#{e[:from].title})" if e[:from] != note && !ctx[:proof_of]
        href = (e[:from] == note ? "" : url(e[:from])) + "##{e[:ref][:id]}"
        (ctx[:proof_of] ? proofs : others) << %(<a href="#{href}">#{CGI.escapeHTML(text)}</a>)
      end
      proofs.uniq!
      others.uniq!
      total = proofs.size + others.size
      # In more than BACKREFS_SHOWN places: proofs always show; the other places start hidden
      # behind a "Show all" button (assets/js/notes.js; without JavaScript everything shows)
      if total > BACKREFS_SHOWN && others.any?
        sep = proofs.any? ? " · " : ""
        return %(<div class="env-backrefs" markdown="0">Referenced in (#{total}): #{proofs.join(" · ")}) +
               %(<span class="backrefs-more">#{sep}#{others.join(" · ")}</span>) +
               %( <button type="button" class="backrefs-toggle" hidden>) +
               %(#{proofs.any? ? "Show #{others.size} more" : "Show all #{total}"}</button></div>)
      end
      %(<div class="env-backrefs" markdown="0">Referenced in: #{(proofs + others).join(" · ")}</div>)
    end
  end

  # Folder names -> topic names: _data/note_topics.yml, else "metric-spaces" -> "Metric Spaces"
  def self.topic_name(site, folder)
    names = site.data["note_topics"] || {}
    names[folder] || folder.split(/[-_]/).map(&:capitalize).join(" ")
  end

  # Sets each note's address, topic, and "Notes > Topic > Subtopic" path from its folder.
  def self.organize(site, doc)
    rel = doc.relative_path.sub(%r{\A_notes/}, "").sub(/\.[^.\/]+\z/, "")
    folders = rel.split("/")
    base = folders.pop
    url_parts = folders.last == base ? folders : folders + [base]
    doc.data["permalink"] ||= "/math/notes/#{url_parts.join("/")}/"
    names = folders.map { |f| topic_name(site, f) }
    doc.data["topic"] = names.first || "General"
    doc.data["subtopic"] = names.drop(1).join(" › ")
    doc.data["topic_path"] = names
    doc.data["note_key"] = rel
    crumbs = [{ "name" => "Notes", "url" => "/math/notes/" }]
    names.each_with_index do |n, i|
      crumbs << { "name" => n, "url" => "/math/notes/#topic-" + Jekyll::Utils.slugify(names[0..i].join(" ")) }
    end
    doc.data["breadcrumbs"] = crumbs
  end

  # A note without a `description:` would get one from its raw text (callout syntax, labels,
  # [[...]] codes) in search results and link previews; write a clean one instead.
  def self.describe(doc)
    return if doc.data["description"].to_s.strip != ""
    text = doc.content.dup
    text.gsub!(%r{<div class="env-backrefs".*?</div>}m, " ")   # "Referenced in" lists
    text.gsub!(/<[^>]+>/, " ")                       # block HTML from pass 1
    text.gsub!(/\$\$.+?\$\$|\$[^$\n]+\$/m, " ")       # math
    text.gsub!(/\[\[(?:[^\]|]*\|)?([^\]]*)\]\]/, '\1')   # [[target|text]] -> text
    text.gsub!(/^\^[\w-]+\s*$|^\s*[#>]+|[*_`]/, " ")   # labels, headings, quotes, emphasis
    text = text.gsub(/\s+/, " ").strip
    doc.data["description"] = text.length > 160 ? text[0, 157].sub(/\s+\S*\z/, "") + "…" : text
  end

  def self.json_file(site, dir, name, data)
    page = Jekyll::PageWithoutAFile.new(site, site.source, dir, name)
    page.content = JSON.generate(data)
    page.data["layout"] = nil
    page.data["sitemap"] = false
    site.pages << page
  end

  # Put the protected math back once the page (and its layout) has been rendered
  Jekyll::Hooks.register :notes, :post_render do |doc|
    AcademicNotes.restore_math(doc)
  end

  Jekyll::Hooks.register :site, :post_read do |site|
    collection = site.collections["notes"]
    next unless collection
    collection.docs.each { |d| AcademicNotes.organize(site, d) }
    notes = collection.docs.map { |d| Note.new(d) }
    begin
      notes.each(&:transform!)
      linker = Linker.new(site, notes)
      notes.each { |n| linker.link!(n) }
      notes.each { |n| AcademicNotes.describe(n.doc) }
      site.data["notes_index"] = linker.index
      site.data["notes_graph"] = linker.graph
      # Served as separate files, fetched by the pages that need them (keeps those pages small
      # and lets the browser cache the data): the Notes Map and the statement index.
      AcademicNotes.json_file(site, "math/notes", "graph.json", site.data["notes_graph"])
      AcademicNotes.json_file(site, "math/notes", "statements.json", site.data["notes_index"])
      notes.each { |n| AcademicNotes.protect_math(n.doc) }
    rescue Error => e
      raise Jekyll::Errors::FatalException, "Academic notes: #{e.message}"
    end
  end
end
