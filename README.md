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

## Broken links

A GitHub workflow (`.github/workflows/check-links.yml`) checks every link on the site each Monday
and keeps an issue labeled `broken-links` up to date (it closes the issue once everything passes).
Run it any time with `gh workflow run "Check links"`. Links that are fine but fail the check can be
ignored in `.lychee.toml`.

## License

Code is MIT-licensed; writing, photos, and the CV are © Carlos A. Taveras, all rights reserved.
See `LICENSE.md`.
