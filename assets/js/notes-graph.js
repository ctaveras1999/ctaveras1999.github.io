// Notes Map (/math/notes/graph/): an interactive directed graph of references between notes
// and between statements (definitions, theorems, ...). Data comes from the academic-notes
// plugin (site.data.notes_graph); drawing uses Cytoscape.js with the dagre layered layout.
// The data says "A refers to B"; the map draws the arrow the other way, B -> A, from what is
// built on to what builds on it (a definition points to the theorems that invoke it). The
// layout follows the arrows downward, so foundations sit on top.
//
// Big maps: drawing hundreds of boxes takes the layout a long time, so above MAX_DRAW boxes the
// map asks for a topic or a focus first (with a "Draw anyway" button). The layered layout's time
// grows with the number of arrows (about 2 s at 400, 6 s at 900), so drawings above MAX_DAGRE
// boxes or MAX_DAGRE_EDGES arrows use a quicker, plainer layout (under a second even for 3,000).
(function () {
  "use strict";
  var box = document.getElementById("notes-graph");
  if (!window.cytoscape) {
    box.textContent = "The map couldn't load (its drawing library is unavailable).";
    return;
  }
  // The data is a separate file (built by the plugin), so this page stays small
  fetch(box.dataset.src)
    .then(function (r) { return r.ok ? r.json() : Promise.reject(r.status); })
    .then(start)
    .catch(function () { box.textContent = "The map's data couldn't load."; });

  function start(data) {
    var MAX_DRAW = 150, MAX_DAGRE = 150, MAX_DAGRE_EDGES = 400;
    try { cytoscape.use(cytoscapeDagre); } catch (e) { /* already registered */ }
    var hasDagre = true;
    try { cytoscape({ headless: true }).layout({ name: "dagre" }); } catch (e) { hasDagre = false; }

    var $ = function (id) { return document.getElementById(id); };
    var ui = {
      level: $("g-level"), topic: $("g-topic"), group: $("g-group"), isolated: $("g-isolated"),
      types: $("g-types"), focus: $("g-focus"), focusList: $("g-focus-list"), dir: $("g-dir"),
      depth: $("g-depth"), clear: $("g-clear"), info: $("g-info"), status: $("g-status"), big: $("g-big")
    };

    // One color per statement type (white text on each is at least 5.8:1). Definitions and
    // theorems keep the purples from the notes; the type checkboxes show these as a legend.
    var COLORS = {
      Definition: "#692e9d", Theorem: "#421d63", Lemma: "#2b5d8c", Proposition: "#1d6b5a",
      Corollary: "#8a4a1c", Claim: "#5e5a1a", Example: "#8445c0", Exercise: "#a33a6e",
      Solution: "#a33a6e", Axiom: "#3d4f8f", Assumption: "#3d4f8f", Conjecture: "#9b2f2f",
      Hypothesis: "#9b2f2f", Remark: "#5c5c5c"
    };
    // Boxes on the map use the usual abbreviations ("Thm. 1.3"); the details panel and the
  // focus search keep the full names
  var ABBREV = {
    Definition: "Def.", Theorem: "Thm.", Lemma: "Lem.", Proposition: "Prop.", Corollary: "Cor.",
    Example: "Ex.", Exercise: "Exer.", Solution: "Sol.", Assumption: "Assump.", Conjecture: "Conj.",
    Hypothesis: "Hyp.", Remark: "Rem."
  };
  var short = function (label) {
    return label.replace(/^\S+/, function (w) { return ABBREV[w] || w; });
  };
  var TITLE_BAR = "#4f5866";   // note title bars: slate, unlike any statement type
    var color = function (type) { return COLORS[type] || "#7f37bd"; };

    var byId = {};
    data.nodes.forEach(function (n) { byId[n.id] = n; });
    var plain = function (s) { return (s || "").replace(/\$/g, "").replace(/\\[a-zA-Z]+\s?/g, "").trim(); };

    // ---------- Controls ----------
    var types = [];
    data.nodes.forEach(function (n) { if (n.type && types.indexOf(n.type) === -1) types.push(n.type); });
    var order = ["Definition", "Theorem", "Lemma", "Proposition", "Corollary", "Claim", "Example", "Exercise"];
    types.sort(function (a, b) {
      var ia = order.indexOf(a), ib = order.indexOf(b);
      return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib) || a.localeCompare(b);
    });
    var plural = function (t) {
      return { Corollary: "Corollaries", Hypothesis: "Hypotheses", Axiom: "Axioms" }[t] || t + "s";
    };
    var activeTypes = {};
    types.forEach(function (t) {
      activeTypes[t] = true;
      var label = document.createElement("label");
      label.className = "g-type";
      label.innerHTML = '<input type="checkbox" checked> <span class="g-swatch"></span> ';
      label.querySelector(".g-swatch").style.background = color(t);
      label.appendChild(document.createTextNode(plural(t)));
      label.querySelector("input").addEventListener("change", function (e) { activeTypes[t] = e.target.checked; draw(); });
      ui.types.appendChild(label);
    });

    var topics = [];
    data.nodes.forEach(function (n) {
      if (n.kind !== "note" || !n.topic) return;
      var parts = n.topic.split(" › ");
      for (var i = 1; i <= parts.length; i++) {
        var t = parts.slice(0, i).join(" › ");
        if (topics.indexOf(t) === -1) topics.push(t);
      }
    });
    topics.sort().forEach(function (t) {
      var o = document.createElement("option");
      o.value = t;
      o.textContent = t;
      ui.topic.appendChild(o);
    });

    function focusName(n) {
      return n.kind === "note" ? n.label : n.label + (n.title ? " · " + plain(n.title) : "") + " (" + n.noteTitle + ")";
    }
    data.nodes.forEach(function (n) {
      var o = document.createElement("option");
      o.value = focusName(n);
      ui.focusList.appendChild(o);
    });
    var focusId = null;
    function focusFromInput() {
      var v = ui.focus.value.trim();
      var match = data.nodes.filter(function (n) { return focusName(n) === v; })[0];
      focusId = match ? match.id : null;
      draw();
    }

    // ---------- Which nodes and edges to show ----------
    function visible() {
      var level = ui.level.value;
      var topic = ui.topic.value;
      var nodes = data.nodes.filter(function (n) {
        if (level === "notes" ? n.kind !== "note" : n.kind !== "statement") return false;
        if (level === "statements" && !activeTypes[n.type]) return false;
        if (topic && (n.topic || "") !== topic && (n.topic || "").indexOf(topic + " › ") !== 0) return false;
        return true;
      });
      var ids = {};
      nodes.forEach(function (n) { ids[n.id] = true; });
      var kind = level === "notes" ? "note" : "statement";
      var edges = data.edges.filter(function (e) { return e.kind === kind && ids[e.source] && ids[e.target]; });

      // Focus: keep what is within `depth` steps of the focused item(s), following the chosen direction
      var seeds = [];
      if (focusId && byId[focusId]) {
        var f = byId[focusId];
        if (level === "notes") seeds = [f.kind === "note" ? f.id : f.note];
        else seeds = f.kind === "statement" ? [f.id] : nodes.filter(function (n) { return n.note === f.id; }).map(function (n) { return n.id; });
        seeds = seeds.filter(function (s) { return ids[s]; });
      }
      if (seeds.length) {
        var dir = ui.dir.value, depth = parseInt(ui.depth.value, 10);
        var keep = {}, frontier = seeds.slice();
        seeds.forEach(function (s) { keep[s] = true; });
        for (var d = 0; d < depth && frontier.length; d++) {
          var next = [];
          edges.forEach(function (e) {
            if (dir !== "in" && frontier.indexOf(e.source) !== -1 && !keep[e.target]) { keep[e.target] = true; next.push(e.target); }
            if (dir !== "out" && frontier.indexOf(e.target) !== -1 && !keep[e.source]) { keep[e.source] = true; next.push(e.source); }
          });
          frontier = next;
        }
        nodes = nodes.filter(function (n) { return keep[n.id]; });
        edges = edges.filter(function (e) { return keep[e.source] && keep[e.target]; });
      }
      if (ui.isolated.checked) {
        var linked = {};
        edges.forEach(function (e) { linked[e.source] = linked[e.target] = true; });
        seeds.forEach(function (s) { linked[s] = true; });
        nodes = nodes.filter(function (n) { return linked[n.id]; });
      }
      return { nodes: nodes, edges: edges, seeds: seeds };
    }

    // ---------- Drawing ----------
    var cy = cytoscape({
      container: box,
      wheelSensitivity: 0.25,
      minZoom: 0.2,
      maxZoom: 2.5,
      style: [
        { selector: "node", style: {
          "shape": "round-rectangle", "label": "data(label)", "text-wrap": "wrap", "text-max-width": 160,
          "text-valign": "center", "text-halign": "center", "font-family": "IBM Plex Mono, monospace",
          "font-size": 11, "width": "label", "height": "label", "padding": "8px",
          "background-color": "data(color)", "color": "#fff", "border-width": 1, "border-color": "#000" } },
        { selector: "node.note", style: {
          "background-color": "#c0c0c0", "color": "#000", "border-width": 2, "font-size": 12, "font-weight": 600 } },
        // Note boxes (statements grouped by note). The title is a separate "title bar" node
        // placed across the top inside the box after layout (see placeTitleBars)
        { selector: ":parent", style: {
          "shape": "rectangle", "background-color": "#efe6f7", "background-opacity": 0.6, "border-style": "dashed",
          "border-color": "#7f37bd", "padding": 0, "label": "" } },
        // Title bars span the whole box, text centered, drawn on top of arrows passing through
        { selector: "node.note-title", style: {
          "shape": "rectangle", "background-color": TITLE_BAR, "color": "#fff", "border-width": 0,
          "font-size": 11, "font-weight": 600, "text-wrap": "wrap", "text-max-width": "data(maxw)",
          "text-halign": "center", "text-valign": "center", "height": "label", "padding": "5px",
          "z-compound-depth": "top", "z-index-compare": "manual", "z-index": 100 } },
        // Invisible strip below the statements, giving the box its bottom margin
        { selector: "node.note-spacer", style: { "opacity": 0, "events": "no", "label": "" } },
        { selector: "edge", style: {
          "z-index-compare": "manual", "z-index": 1,
          "curve-style": "bezier", "width": "data(width)", "line-color": "#808080",
          "target-arrow-shape": "triangle", "target-arrow-color": "#808080", "arrow-scale": 1.1 } },
        { selector: "node.seed", style: { "border-width": 4, "border-color": "#e6b422" } },
        { selector: "node:selected", style: { "border-width": 4, "border-color": "#e6b422" } },
        { selector: ".faded", style: { "opacity": 0.25 } }
      ]
    });

    // Too many boxes: say so instead of drawing, unless "Draw anyway" was pressed for these settings
    var force = false;
    function tooBig(v, level) {
      var what = level === "notes" ? "notes" : "definitions and theorems";
      ui.big.innerHTML = "";
      var p = document.createElement("p");
      p.textContent = "These settings show " + v.nodes.length + " " + what + ", too many to draw quickly. " +
        (focusId ? "Try fewer steps, one direction, or a topic" : "Pick a topic or focus on a note above") +
        (level === "statements" ? ", or switch to Notes" : "") + ".";
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "cv-button";
      btn.textContent = "Draw anyway";
      btn.addEventListener("click", function () { force = true; draw(); force = false; });
      ui.big.appendChild(p);
      ui.big.appendChild(btn);
      ui.big.hidden = false;
      box.style.display = "none";
      cy.elements().remove();
      ui.info.hidden = true;
      ui.status.textContent = "";
    }

    function draw() {
      var v = visible();
      var level = ui.level.value;
      document.querySelectorAll(".g-statements-only").forEach(function (el) { el.hidden = level !== "statements"; });
      updateUrl();
      if (v.nodes.length > MAX_DRAW && !force) return tooBig(v, level);
      ui.big.hidden = true;
      if (box.style.display === "none") { box.style.display = ""; cy.resize(); }
      var big = v.nodes.length > MAX_DAGRE || v.edges.length > MAX_DAGRE_EDGES;
      var els = [];
      var parents = {};
      v.nodes.forEach(function (n) {
        var d = { id: n.id, color: color(n.type) };
        if (n.kind === "note") d.label = n.label;
        else d.label = short(n.label) + (n.title ? "\n" + plain(n.title) : "");
        if (level === "statements" && ui.group.checked && !big) {
          d.parent = n.note;
          parents[n.note] = true;
        }
        els.push({ group: "nodes", data: d, classes: n.kind + (v.seeds.indexOf(n.id) !== -1 ? " seed" : "") });
      });
      Object.keys(parents).forEach(function (p) {
        els.push({ group: "nodes", data: { id: p, color: "#efe6f7" }, classes: "group" });
        // The note's title bar, inside its box (positioned after layout)
        els.push({ group: "nodes", data: { id: p + "::title", parent: p, note: p, maxw: 300,
                                           label: byId[p] ? byId[p].label : p }, classes: "note-title" });
        els.push({ group: "nodes", data: { id: p + "::spacer", parent: p }, classes: "note-spacer" });
      });
      v.edges.forEach(function (e) {
        // Arrow from the referenced item (e.target) to the one that refers to it (e.source)
        els.push({ group: "edges", data: { id: e.target + " -> " + e.source, source: e.target, target: e.source,
                                           width: Math.min(1.5 + (e.weight || 1) * 0.75, 6) } });
      });
      cy.elements().remove();
      cy.add(els);
      // Lay out everything except the title bars, then put each title bar across the top of its box
      // Big drawings skip the note boxes and use the quicker breadthfirst layout
      cy.elements().not(".note-title, .note-spacer").layout(hasDagre && !big
        ? { name: "dagre", rankDir: "TB", nodeSep: 30, rankSep: 70, padding: 20, animate: false }
        : { name: "breadthfirst", directed: true, padding: 20, spacingFactor: 0.9, animate: false }).run();
      placeTitleBars();
      cy.fit(undefined, 30);
      if (cy.zoom() > 1.3) { cy.zoom(1.3); cy.center(); }
      ui.info.hidden = true;
      var shown = v.nodes.length, links = v.edges.length;
      ui.status.textContent = shown
        ? shown + (level === "notes" ? (shown === 1 ? " note" : " notes") : (shown === 1 ? " statement" : " statements")) +
          ", " + links + (links === 1 ? " reference" : " references")
        : "Nothing matches these settings.";
      if (big) ui.status.textContent += " (a large map: drawn without note boxes, in a simpler layout)";
    }

    // Each box is sized by its title bar (top), a spacer (bottom), and its statements. The box
    // has no padding, so the title bar, made 2*MARGIN wider than the statements, is exactly as
    // wide as the box.
    var MARGIN = 12;
    function placeTitleBars() {
      cy.nodes(".note-title").forEach(function (title) {
        var box = title.parent();
        var members = box.children().not(".note-title, .note-spacer");
        if (!members.length) return;
        var bb = members.boundingBox({ includeLabels: false });
        var width = bb.w + 2 * MARGIN;   // no wider than the layout allowed for (frames would overlap)
        var cx = bb.x1 + bb.w / 2;
        title.data("maxw", width - 16);
        title.style("width", width);
        title.position({ x: cx, y: bb.y1 - MARGIN - title.outerHeight() / 2 });
        var spacer = box.children(".note-spacer");
        spacer.style({ width: width, height: MARGIN });
        spacer.position({ x: cx, y: bb.y2 + MARGIN / 2 });
      });
    }

    // ---------- Details and navigation ----------
    function showInfo(id) {
      var n = byId[id];
      if (!n) return;
      // Arrows point from what is used to what uses it: incoming arrows = what it uses
      var node = cy.getElementById(id);
      var out = node.length ? node.incomers("edge").length : 0, inc = node.length ? node.outgoers("edge").length : 0;
      var title = n.kind === "note" ? n.label : n.label + (n.title ? " · " + plain(n.title) : "");
      ui.info.innerHTML = "";
      var h = document.createElement("strong");
      h.textContent = title;
      ui.info.appendChild(h);
      var meta = document.createElement("span");
      meta.textContent = (n.kind === "note" ? (n.topic || "") : n.noteTitle) +
        (node.length ? " · uses " + out + " · used by " + inc : "");
      ui.info.appendChild(meta);
      var open = document.createElement("a");
      open.href = n.url;
      open.textContent = "Open";
      open.className = "cv-button";
      var focus = document.createElement("button");
      focus.type = "button";
      focus.className = "cv-button";
      focus.textContent = "Focus here";
      focus.addEventListener("click", function () { ui.focus.value = focusName(n); focusFromInput(); });
      ui.info.appendChild(open);
      ui.info.appendChild(focus);
      ui.info.hidden = false;
    }
    // A title bar stands for its note
    var nodeId = function (el) { return el.hasClass("note-title") ? el.data("note") : el.id(); };
    cy.on("tap", "node", function (e) { if (!e.target.isParent()) showInfo(nodeId(e.target)); });
    cy.on("dbltap", "node", function (e) { var n = byId[nodeId(e.target)]; if (n && !e.target.isParent()) location.href = n.url; });
    cy.on("tap", function (e) { if (e.target === cy) ui.info.hidden = true; });
    cy.on("mouseover", "node", function (e) {
      if (e.target.isParent() || e.target.hasClass("note-title") || e.target.hasClass("note-spacer")) return;
      var hood = e.target.closedNeighborhood();
      cy.elements().not(hood).not(":parent").not(".note-title, .note-spacer").addClass("faded");
    });
    cy.on("mouseout", "node", function () { cy.elements().removeClass("faded"); });

    // ---------- Settings in the address, so focused views can be linked ----------
    function updateUrl() {
      var p = new URLSearchParams();
      if (ui.level.value !== "notes") p.set("level", ui.level.value);
      if (ui.topic.value) p.set("topic", ui.topic.value);
      if (focusId) p.set("focus", focusId);
      var q = p.toString();
      history.replaceState(null, "", location.pathname + (q ? "?" + q : ""));
    }
    var params = new URLSearchParams(location.search);
    if (params.get("level") === "statements") ui.level.value = "statements";
    if (params.get("topic")) ui.topic.value = params.get("topic");
    if (params.get("focus") && byId[params.get("focus")]) {
      focusId = params.get("focus");
      ui.focus.value = focusName(byId[focusId]);
    }

    [ui.level, ui.topic, ui.group, ui.isolated, ui.dir, ui.depth].forEach(function (c) { c.addEventListener("change", draw); });
    ui.focus.addEventListener("change", focusFromInput);
    ui.clear.addEventListener("click", function () { ui.focus.value = ""; focusId = null; draw(); });
    window.addEventListener("resize", function () { cy.resize(); cy.fit(undefined, 30); });
    draw();
  }
})();
