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
