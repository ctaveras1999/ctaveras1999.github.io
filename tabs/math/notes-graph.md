---
title: "Notes Map"
permalink: "/math/notes/graph/"
layout: page
description: "A map of how my math notes, definitions, and theorems refer to each other."
---
{%- comment -%}
  Interactive graph of references between notes (data: /math/notes/graph.json from _plugins/academic_notes.rb,
  drawing and controls in assets/js/notes-graph.js). Links like ?focus=note:<path> or
  ?level=statements&focus=st:<path>#<id> open it focused.
{%- endcomment -%}
How the [notes]({{ '/math/notes/' | relative_url }}) refer to each other. An arrow from A to B means
**B builds on A** (B refers to A), so foundations sit at the top and arrows flow down to what uses them. Click a box for details;
double-click to open it.

<div class="graph-controls">
  <label>Show <select id="g-level">
    <option value="notes">Notes</option>
    <option value="statements">Definitions &amp; theorems</option>
  </select></label>
  <label>Topic <select id="g-topic"><option value="">All topics</option></select></label>
  <label class="g-statements-only"><input type="checkbox" id="g-group" checked> Group by note</label>
  <label><input type="checkbox" id="g-isolated"> Hide unconnected</label>
</div>
<div class="graph-controls g-statements-only" id="g-types" role="group" aria-label="Statement types"></div>
<div class="graph-controls">
  <label>Focus on <input type="search" id="g-focus" list="g-focus-list" placeholder="a note or statement…"></label>
  <datalist id="g-focus-list"></datalist>
  <label><select id="g-dir">
    <option value="both">uses &amp; used by</option>
    <option value="out">what it uses</option>
    <option value="in">what uses it</option>
  </select></label>
  <label>within <select id="g-depth">
    <option value="1">1 step</option>
    <option value="2" selected>2 steps</option>
    <option value="3">3 steps</option>
    <option value="99">any distance</option>
  </select></label>
  <button type="button" class="cv-button" id="g-clear">Clear focus</button>
</div>

<div id="g-big" class="graph-big" hidden></div>
<div id="notes-graph" class="graph-canvas" aria-label="Map of notes and their references" data-src="{{ '/math/notes/graph.json' | relative_url }}"></div>
<div id="g-info" class="graph-info" hidden></div>
<p class="graph-status" id="g-status"></p>

<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.2/cytoscape.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/dagre/0.8.5/dagre.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cytoscape-dagre@2.5.0/cytoscape-dagre.js"></script>
<script src="{{ '/assets/js/notes-graph.js' | relative_url }}?v={{ site.time | date: '%s' }}"></script>
