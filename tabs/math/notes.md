---
title: "Notes"
permalink: "/math/notes/"
layout: page
mathjax: true
section: math
category: "Notes"
tags: [Notes]
date: 2026-11-23
description: "My math notes, with numbered definitions and theorems that link to each other."
---
{%- comment -%}
  Notes are grouped by their folders in _notes/ (topic, then subtopic; see _plugins/academic_notes.rb).
{%- endcomment %}
Notes on topics I'm learning, grouped by subject. Definitions and theorems are numbered, and
references to them (including across notes) link straight to the statement.
See how they connect on the [Notes Map]({{ '/math/notes/graph/' | relative_url }}).

<div class="topic-controls" hidden><button type="button" class="cv-button" data-topics="open">Expand all</button> <button type="button" class="cv-button" data-topics="close">Collapse all</button></div>
<div class="topic-groups">
{%- assign topics = site.notes | group_by: "topic" | sort: "name" %}
{%- for topic in topics %}
{%- assign tcount = topic.items | size %}
<details class="topic-group" id="topic-{{ topic.name | slugify }}">
<summary><h2>{{ topic.name }}</h2><span class="topic-count">{{ tcount }} {% if tcount == 1 %}note{% else %}notes{% endif %}</span></summary>
{%- assign subtopics = topic.items | group_by: "subtopic" | sort: "name" %}
{%- for sub in subtopics %}
{%- assign scount = sub.items | size %}
{%- if sub.name != "" %}
<details class="topic-group topic-sub" id="topic-{{ topic.name | append: ' ' | append: sub.name | replace: ' › ', ' ' | slugify }}">
<summary><h3>{{ sub.name }}</h3><span class="topic-count">{{ scount }} {% if scount == 1 %}note{% else %}notes{% endif %}</span></summary>
{%- endif %}
<ul class="page-list notes-list">
{%- assign notes = sub.items | sort: "title" %}
{%- for n in notes %}
  <li>
    <div>
      <a href="{{ n.url | relative_url }}">{{ n.title }}</a>
      {%- if n.description %}<p>{{ n.description }}</p>{% endif %}
    </div>
  </li>
{%- endfor %}
</ul>
{%- if sub.name != "" %}
</details>
{%- endif %}
{%- endfor %}
</details>
{%- endfor %}
</div>
<script>
  // Collapsible topics: all start collapsed on every load; a link to a group (e.g. "Analysis"
  // in a note's path line) opens it; Expand all / Collapse all buttons.
  (function () {
    var groups = Array.prototype.slice.call(document.querySelectorAll(".topic-group"));
    try { localStorage.removeItem("notes-open-topics"); } catch (e) {}   // drop the old saved state
    function openTarget() {
      var el = location.hash && document.getElementById(decodeURIComponent(location.hash.slice(1)));
      if (!el || !el.classList.contains("topic-group")) return;
      for (var p = el; p; p = p.parentElement) if (p.tagName === "DETAILS") p.open = true;
      el.scrollIntoView();
    }
    openTarget();
    window.addEventListener("hashchange", openTarget);
    var controls = document.querySelector(".topic-controls");
    controls.hidden = false;
    controls.addEventListener("click", function (e) {
      var mode = e.target.dataset && e.target.dataset.topics;
      if (!mode) return;
      groups.forEach(function (g) { g.open = mode === "open"; });
    });
  })();
</script>

## Definitions and Theorems
Every numbered statement across the notes. Pick a type, search, or sort by name.

{% include filterable-list.html data=site.data.notes_index src="/math/notes/statements.json" id="statements" limit=15 sort_key="none" topic_order="data" topics_open=true topics_label="Filter by type" placeholder="Search statements and notes…" sorts="original:By note|name:Name, A–Z" %}
