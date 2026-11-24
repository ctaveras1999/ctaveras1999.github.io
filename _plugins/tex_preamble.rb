# Makes the LaTeX macros in _latex/preamble.sty available to MathJax on every page with math.
#
# The file is an ordinary LaTeX preamble (\newcommand / \renewcommand / \def lines, comments
# allowed), so it can be copied straight from a paper or notes project. The build reads it into
# site.data["mathjax_macros"], which _includes/math.html hands to MathJax. A few things only
# LaTeX understands are adjusted on the way (see COMPAT); anything else in the file, such as
# \usepackage, is ignored.
module TexPreamble
  FILE = "_latex/preamble.sty"

  # LaTeX-only pieces -> MathJax equivalents
  ACCENTS = { "a" => "ä", "e" => "ë", "i" => "ï", "o" => "ö", "u" => "ü",
              "A" => "Ä", "E" => "Ë", "I" => "Ï", "O" => "Ö", "U" => "Ü" }.freeze
  COMPAT = [
    [/\\mathds\s*\{/, "\\mathbb{"],                          # dsfont isn't available; \mathbb is the closest
    [/\\xspace\b/, ""],                                       # text-mode spacing helper; no meaning in math
    [/\\"\{?([aeiouAEIOU])\}?/, ->(m) { ACCENTS[m[1]] }]      # \"o in \text{...} -> ö
  ].freeze

  def self.strip_comments(text)
    text.each_line.map { |l| l.sub(/(?<!\\)%.*/, "") }.join
  end

  # Reads a {...} group starting at text[i] == "{"; returns [contents, index after the group]
  def self.group(text, i)
    depth = 0
    j = i
    while j < text.length
      c = text[j]
      if c == "\\" then j += 2; next
      elsif c == "{" then depth += 1
      elsif c == "}"
        depth -= 1
        return [text[i + 1...j], j + 1] if depth.zero?
      end
      j += 1
    end
    raise "unbalanced braces near: #{text[i, 60].inspect}"
  end

  def self.parse(source)
    text = strip_comments(source)
    macros = {}
    pos = 0
    while (m = text.match(/\\(?:re)?newcommand\*?\s*|\\providecommand\*?\s*|\\def\s*/, pos))
      i = m.end(0)
      if m[0].start_with?("\\def")
        name = text[i..][/\A\\[A-Za-z]+/] or (pos = i; next)
        i += name.length
        params = text[i..][/\A(#\d)*/]
        i += params.length
        nargs = params.scan(/#\d/).size
      else
        if text[i] == "{"
          name, i = group(text, i)
          name = name.strip
        else
          name = text[i..][/\A\\[A-Za-z]+/] or (pos = i; next)
          i += name.length
        end
        i += text[i..][/\A\s*/].length
        nargs = 0
        if (n = text[i..][/\A\[(\d)\]/])
          nargs = n[1].to_i
          i += n.length
          i += text[i..][/\A\s*/].length
        end
        default = nil
        if text[i] == "["
          close = text.index("]", i)
          default = text[i + 1...close]
          i = close + 1
          i += text[i..][/\A\s*/].length
        end
      end
      body, pos = group(text, i)
      COMPAT.each { |pat, rep| body = rep.is_a?(Proc) ? body.gsub(pat) { rep.call(Regexp.last_match) } : body.gsub(pat, rep) }
      body = body.strip
      key = name.sub(/\A\\/, "")
      macros[key] =
        if default then [body, nargs, default]
        elsif nargs.positive? then [body, nargs]
        else body
        end
    end
    macros
  end

  Jekyll::Hooks.register :site, :post_read do |site|
    path = File.join(site.source, FILE)
    next unless File.exist?(path)
    begin
      site.data["mathjax_macros"] = parse(File.read(path, encoding: "UTF-8"))
    rescue => e
      raise Jekyll::Errors::FatalException, "#{FILE}: #{e.message}"
    end
  end
end
