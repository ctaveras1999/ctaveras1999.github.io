---
title: "Math and AI"
permalink: "/math/mathai"
layout: page
section: math
category: "Math and AI"
tags: [AI, Lists]
date: 2026-11-02
description: "A running list of responses from the math community to AI in mathematics."

redirect_from:
  - "/blog/mathai"
---
<nav class="toc" aria-label="On this page">
<a href="#purpose">Purpose</a>
<a href="#timeline">Timeline</a>
<a href="#the-list">The List</a>
</nav>

## Purpose
The rapid development of AI and its mathematical capabilities has forced the math community to grapple with many of its long-held traditions and tenets, at both the practical and philosophical level.
During this unpredictable transitionary period, many in the community have shared their views on the past, present, and future of math.
Notably, the perspectives and predictions shared so far have been quite varied.

I thought it might be useful, then, to compile a list[^bloom] of these responses to (hopefully) help early-career academics get a sense for what's ahead and to document events as they happen.
I plan to update this page as frequently as possible. If you have any suggestions on things to include, please reach out (via email)!

## Timeline
Here's my attempt at documenting events relating AI to math, academia, and society.

{%- comment -%} The three newest events from the timeline page (tabs/math/mathai-timeline.md) {%- endcomment %}
<div class="tl-latest">
<p class="tl-latest-head">Latest on the timeline</p>
<ul>
{%- for e in site.data.timelines.mathai limit: 3 %}
<li class="{% if e.type %}tl-type-{{ e.type | slugify }}{% endif %}{% if e.follows %} tl-followup{% endif %}"><time datetime="{{ e.date }}">{{ e.date | date: "%b %-d, %Y" }}</time>{% if e.type %} <span class="tl-type">{{ e.type }}</span>{% endif %} <a href="{{ e.url }}">{{ e.title_html }}</a></li>
{%- endfor %}
</ul>
<p><a href="{{ '/math/mathai/timeline/' | relative_url }}">Full timeline →</a></p>
</div>

## The List
Blog posts, essays, talks, interviews, and more.
Pick a type to narrow things down, search for a person or topic, or sort by type, title, or person.
{% comment %} To add to the list, copy an entry in _data/mathai.yml (instructions at the top of that file). {% endcomment %}

{% include filterable-list.html data=site.data.mathai id="mathai" limit=10 sort_key="none" topic_order="data" topics_open=true topics_label="Filter by type" placeholder="Search titles, people, topics…" sorts="date:Newest first|original:Grouped by type|name:Title, A–Z|aff:Person, A–Z" %}

[^bloom]: Also check out Thomas Bloom's [AI Links](https://thomasbloom.org/AIlinks.html).

