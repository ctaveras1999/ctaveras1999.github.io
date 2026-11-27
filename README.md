# ctaveras1999.github.io

Personal website, built with Jekyll and deployed to GitHub Pages by `.github/workflows/jekyll.yml` on every push to `master`.

Started from the [Contrast](https://github.com/niklasbuschmann/contrast) theme.

## Run locally

    bundle install
    bundle exec jekyll serve -l -o

## Where things live

- `index.md`: homepage. `tabs/`: everything else, one folder per menu tab.
- `_config.yml`: site title, description, menu (`navigation`) and footer links (`external`).
- `_data/resources/learning_people.yml`: the searchable list on the Resources page.
- `_sass/` and `assets/css/index.sass`: styles. Colors and font sizes are in `_sass/variables.sass`.
- `media/`: images and the CV.

## CV

`media/docs/cv.pdf` is generated from the same data as the Academic page:

    ruby cv/build.rb

- Content: `_data/cv.yml` (education, teaching, awards, events, …) and `_data/pubs.yml` (publications and presentations).
  Fields under `cv:` apply to the PDF only; `cv: false` leaves an entry off the PDF.
- Layout: `cv/template.tex.erb` (LaTeX). Needs a LaTeX install with `latexmk` and `pdflatex`.
- The build also updates the "Last updated" date on the Academic page (`_data/cv_build.yml`).

## Adding to the Math and AI list

    ruby scripts/add-link.rb URL --type "Talks & Panels" [--people "A and B"] [--dry-run]

Fetches the title, date, and source (YouTube channel, site, or arXiv, plus authors for papers)
and adds the entry to `_data/mathai.yml` at the top of its type's group. Check the entry before
committing; speakers usually need `--people`. Run it without arguments to see all options.

## Math and AI timeline

`tabs/math/mathai-timeline.md` (`/math/mathai/timeline/`) is drawn as a vertical timeline,
newest first, with a divider per year; the three newest events also show on the Math and AI
page. Add an event anywhere in the file:

    ### Title of the event
    {: date="2026-11-20" type="Result"}

    One or two sentences, always shown.

    <!-- more -->
    The full write-up (quotes, footnotes, ...), folded under "Read more".

Optional attributes on the `{: ...}` line:
- `type`: a tag (Result, Statement, Reaction, Event, Release have their own colors in `_sass/retro.sass`).
- `id="short-name"`: the event's link, `/math/mathai/timeline/#short-name`. Without it the link
  is the date (`#2026-11-20`), or date plus title when several events share the date, so give
  same-day events an id if you'll link to them.
- `follows="short-name"`: a follow-up to an earlier event (hollow marker and a link back).
- `time="14:30"`: only for ordering. Same-day events show in the order they're written in the
  file (top = top of the page) unless every one of them has a time (then latest on top).
Implementation: `_plugins/timeline.rb`; any page can become a timeline with `timeline: <name>`.

## Broken links

A GitHub workflow (`.github/workflows/check-links.yml`) checks every link on the site each Monday
and fails (with the broken links listed on the run's summary page) if any are broken; GitHub emails you when it fails.
Run it any time with `gh workflow run "Check links"`. Links that are fine but fail the check can be
ignored in `.lychee.toml`.

## License

Code is MIT-licensed; writing, photos, and the CV are © Carlos A. Taveras, all rights reserved.
See `LICENSE.md`.

## Post tags

Blog and Math posts (pages with `section: blog` or `section: math`) can have tags in their front
matter, e.g. `tags: [Personal, Lists]`. The Blog and Math pages show a row of all tags and each
post's tags; clicking one shows only matching posts, and the filter is kept in the address
(`/blog/?tag=Lists`). Each post shows its tags at the top, linking to that filtered list.

## Math and LaTeX macros

Math is typeset by MathJax (`_includes/math.html`). It loads on the math notes (`mathjax: true`)
and on any page whose Markdown uses `$$...$$`; to use single-`$` inline math on another page,
add `mathjax: true` to its front matter.

The macros in `_latex/preamble.sty` work on every page with math. It is a plain LaTeX preamble
(`\newcommand`, `\renewcommand`, `\def`), so paste a new version over it to update the site.
`_plugins/tex_preamble.rb` reads it at build time and adjusts the few LaTeX-only pieces:
`\mathds{1}` becomes `\mathbb{1}`, `\xspace` is dropped, and `\"o` becomes `ö`. A malformed
line (e.g. unbalanced braces) stops the build with a message.

## Math notes

Notes are Markdown files in topic folders under `_notes/`, listed by topic on `/math/notes/`:

    _notes/analysis/metric-spaces/metric-spaces.md  -> /math/notes/analysis/metric-spaces/
    _notes/analysis/metric-spaces/completeness.md   -> /math/notes/analysis/metric-spaces/completeness/
    _notes/topology/topology-basics.md              -> /math/notes/topology/topology-basics/

The folders are the topic ("Analysis › Metric Spaces"); a file named like its folder is that
folder's main page. To recategorize a note, move the file; references keep working. Folder names
become titles automatically (`metric-spaces` → "Metric Spaces"); set special names in
`_data/note_topics.yml` (e.g. `pde: PDE`). Moving a published note changes its address, so add
`redirect_from: [/math/notes/old/path/]` to its front matter if people may have linked to it. They use the syntax of the Obsidian
"Academic Notes" plugin, so they also work in Obsidian:

    > [!thm] Composition
    > If $f$ and $g$ are continuous, so is $g\circ f$.

    ^thm-composition

    > [!proof] [[#^thm-composition]]
    > ...

- Block types: def, thm, lem, prop, cor, claim, example, exercise, axiom, assumption,
  conjecture, hypothesis (numbered); proof, remark, solution (unnumbered).
  `[!thm|*]` = unnumbered, `[!thm|A.1]` = manual number, `[!thm]-` = collapsible.
- Numbering restarts at each `## ` heading (2.1, 2.2, ...).
- References: `[[#^label]]` (same note), `[[Other Note#^label]]` (another note, by title or file
  name), `[[#^label|custom text]]`, `[[Other Note]]`. If two notes share a name, use the path:
  `[[analysis/metric-spaces/metric-spaces#^label]]` (the build says when this is needed).
- Equations: `\label{eq:name}` inside `equation`/`align`, referenced with `\eqref{eq:name}`.
- A wrong or duplicate label stops the build with a message saying where.
- Hovering a reference shows the referenced block in a small preview (`assets/js/notes.js`),
  and each labeled block ends with "Referenced in", linking to every reference to it. When a
  block is referenced in more than 5 places, proofs that use it stay listed and the other places
  start hidden behind a "Show N more" button (`BACKREFS_SHOWN` in the plugin).
- `/math/notes/` also has a searchable index of every numbered statement across all notes. Its
  entries load from `/math/notes/statements.json` (written by the plugin) so the page stays small.
- `/math/notes/graph/` (the Notes Map) draws the references as a directed graph (A → B means B
  builds on A, i.e. B refers to A): notes linking to notes, or statements using statements (references inside a
  proof count for the proved statement). Filter by type and topic, focus on one item and its
  neighbors, or hide unconnected items. Each note's path line links to the map focused on it.
  Drawing: `assets/js/notes-graph.js` with Cytoscape.js and dagre from a CDN; data from
  `/math/notes/graph.json` (written by the plugin). For large collections: above 150 boxes the
  map asks for a topic or focus first (with a "Draw anyway" button), and above 150 boxes or 400
  arrows it uses a quicker layout without note boxes (`MAX_DRAW`, `MAX_DAGRE`, `MAX_DAGRE_EDGES`).
- Implementation: `_plugins/academic_notes.rb`; styles at the end of `_sass/retro.sass`.
