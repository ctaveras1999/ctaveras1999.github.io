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

I thought it might be useful, then, to compile a list[^bloom] of these responses to (hopefully) help early-career academics get a sense for what's ahead and to document this evolution as it happens.
I'm hoping to update this list with new blog posts and videos as often as I can. If you have any suggestions on things to include in this list, don't hesitate to reach out (via email)!

## Timeline
### November 20th, 2026: Riemann Hypothesis and Unforced Navier Stokes Solved?
Anthropic mathematician [Levent Alpöge](https://alpo.ge/) posts a [modest-looking four-page document](https://alpo.ge/remark.pdf)[^remark] on his website in which he claims to have proved the 
[Generalized Riemann Hypothesis](https://en.wikipedia.org/wiki/Generalized_Riemann_hypothesis) with the help of Claude. 
As for the proof, he opted to only share links to its Lean formalization and a brief timeline of some significant milestones;
in his words, 

>It being obviously inappropriate to attempt to post some massive unreadable travesty of "slop", I decided to only present Lean.

accompanied by the foot note

>I of course amused myself, and hit 250,000+ pages. 

**Not done yet... will do soon**

## The List
Blog posts, essays, talks, interviews, and more.
Pick a type to narrow things down, search for a person or topic, or sort by type, title, or person.
{% comment %} To add to the list, copy an entry in _data/mathai.yml (instructions at the top of that file). {% endcomment %}

{% include filterable-list.html data=site.data.mathai id="mathai" limit=10 sort_key="none" topic_order="data" topics_open=true topics_label="Filter by type" placeholder="Search titles, people, topics…" sorts="date:Newest first|original:Grouped by type|name:Title, A–Z|aff:Person, A–Z" %}

[^bloom]: Also check out Thomas Bloom's 'AI Links' for a similar list: [link](https://thomasbloom.org/AIlinks.html).

[^remark]: Humorously, titled 'remark.pdf'.