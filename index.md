---
layout: page
window_title: "Homepage"   # shown in the window's title bar (the browser tab keeps your name)
---
# Greetings!

<figure class="intro-photo">
  <img src="/media/pics/personal_pic3-small.jpeg" alt="A picture of me near some trees circa 2026" width="400" height="536">
</figure>

Among other things, I'm a first-year Ph.D. student in the [Rice Math Department](https://math.rice.edu/).
See [Overview]({{ '/overview/' | relative_url }}) for more.

<div class="tab-cards">
  <a class="tab-card" href="{{ '/overview/' | relative_url }}"><strong>Overview</strong><span>More About Me and This Site</span></a>
  <a class="tab-card" href="{{ '/academic/' | relative_url }}"><strong>Academic</strong><span>The Standard Fare</span></a>
  <a class="tab-card" href="{{ '/math/' | relative_url }}"><strong>Math</strong><span>Many Manifestations of Math</span></a>
  <a class="tab-card" href="{{ '/resources/' | relative_url }}"><strong>Resources</strong><span>A List of Lists</span></a>
  <a class="tab-card" href="{{ '/blog/' | relative_url }}"><strong>Blog</strong><span>Mostly Miscellany</span></a>
</div>

## Recent News
{% include news-list.html limit=3 %}
[All news →]({{ '/news/' | relative_url }})
