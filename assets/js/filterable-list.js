// Search, sort, topic filtering and collapsing for lists built by _includes/filterable-list.html.
// No dependencies. Safe to load more than once on a page.
(function () {
  "use strict";

  // Lowercase and strip accents, so "zurich" finds "Zürich" and "peyre" finds "Peyré".
  function norm(s) {
    return (s || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  }

  var collator = new Intl.Collator(undefined, { sensitivity: "base", ignorePunctuation: true });

  function init(root) {
    if (root.dataset.flReady) return;
    root.dataset.flReady = "1";

    var list = root.querySelector(".flist-items");
    var search = root.querySelector(".flist-search");
    var sortSelect = root.querySelector(".flist-sort");
    var count = root.querySelector(".flist-count");
    var empty = root.querySelector(".flist-empty");
    // Two "Show all / Show fewer" buttons: one by the count above the list, one below it.
    var toggles = Array.prototype.slice.call(root.querySelectorAll(".flist-toggle"));
    var topicButtons = Array.prototype.slice.call(root.querySelectorAll(".flist-topic"));
    var topicsPanel = root.querySelector(".flist-topics");
    var topicsToggle = root.querySelector(".flist-topics-toggle");
    var topicsClear = root.querySelector(".flist-topics-clear");
    var limit = parseInt(root.dataset.limit, 10) || 0;
    var activeTopics = [];
    var expanded = false;

    var items = Array.prototype.slice.call(list.querySelectorAll(".flist-item")).map(function (li) {
      return {
        el: li,
        text: norm(li.textContent),
        sort: li.dataset.sort || "",
        aff: li.dataset.aff || "",
        date: li.dataset.date || "",
        topics: (li.dataset.topics || "").split("|").filter(Boolean)
      };
    });
    var ordered = items.slice();

    // Long descriptions are cut to two lines, with a More/Less button that only
    // appears when the text actually overflows (depends on screen width).
    var descs = Array.prototype.slice.call(list.querySelectorAll(".flist-desc")).map(function (desc) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "flist-more";
      btn.hidden = true;
      btn.textContent = "More";
      btn.setAttribute("aria-expanded", "false");
      desc.insertAdjacentElement("afterend", btn);
      desc.classList.add("is-clamped");
      var d = { desc: desc, btn: btn, open: false };
      btn.addEventListener("click", function () {
        d.open = !d.open;
        desc.classList.toggle("is-clamped", !d.open);
        btn.textContent = d.open ? "Less" : "More";
        btn.setAttribute("aria-expanded", d.open ? "true" : "false");
      });
      return d;
    });

    function updateClamps() {
      descs.forEach(function (d) {
        if (d.open || d.desc.offsetParent === null) return; // expanded or not visible
        d.btn.hidden = d.desc.scrollHeight <= d.desc.clientHeight + 1;
      });
    }

    // Decide which entries are visible. While someone is searching or filtering,
    // every match is shown; otherwise the list is cut to `limit` until expanded.
    function render() {
      var terms = norm(search.value).split(/\s+/).filter(Boolean);
      var narrowing = terms.length > 0 || activeTopics.length > 0;
      var collapsing = limit > 0 && !narrowing && !expanded && items.length > limit;
      var matches = 0;
      var shown = 0;

      ordered.forEach(function (it) {
        var ok = terms.every(function (t) { return it.text.indexOf(t) !== -1; }) &&
          (activeTopics.length === 0 || it.topics.some(function (t) { return activeTopics.indexOf(t) !== -1; }));
        if (ok) matches++;
        var visible = ok && (!collapsing || matches <= limit);
        it.el.hidden = !visible;
        if (visible) shown++;
      });

      if (narrowing) {
        count.textContent = "Showing " + matches + " of " + items.length;
      } else {
        count.textContent = shown === items.length
          ? items.length + " entries"
          : "Showing " + shown + " of " + items.length;
      }
      empty.hidden = matches !== 0;

      var canToggle = limit > 0 && !narrowing && items.length > limit;
      toggles.forEach(function (t) {
        t.hidden = !canToggle;
        t.textContent = expanded ? "Show fewer" : "Show all " + items.length;
        t.setAttribute("aria-expanded", expanded ? "true" : "false");
      });
      updateClamps();
    }

    // Fisher–Yates shuffle: every order is equally likely.
    function shuffle(arr) {
      for (var i = arr.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
      }
      return arr;
    }

    function sort() {
      var mode = sortSelect.value;
      if (mode === "original") {
        ordered = items.slice();
        ordered.forEach(function (it) { list.appendChild(it.el); });
        return;
      }
      if (mode === "random") {
        ordered = shuffle(items.slice());
        ordered.forEach(function (it) { list.appendChild(it.el); });
        return;
      }
      ordered = items.slice().sort(function (a, b) {
        if (mode === "date") {
          // Newest first; dates are "YYYY-MM-DD" or "YYYY", so text order is date order. Undated go last,
          // and ties keep the data file's order (Array.prototype.sort is stable).
          if (!a.date !== !b.date) return a.date ? -1 : 1;
          return a.date < b.date ? 1 : a.date > b.date ? -1 : 0;
        }
        if (mode === "aff") {
          // Entries without an affiliation go last.
          if (!a.aff !== !b.aff) return a.aff ? -1 : 1;
          return collator.compare(a.aff, b.aff) || collator.compare(a.sort, b.sort);
        }
        var byName = collator.compare(a.sort, b.sort);
        return mode === "name-desc" ? -byName : byName;
      });
      ordered.forEach(function (it) { list.appendChild(it.el); });
    }

    search.addEventListener("input", render);
    sortSelect.addEventListener("change", function () { sort(); render(); });
    // The topic chips live in a panel opened by the "Filter by topic" button.
    // The button shows how many topics are selected, even while the panel is closed.
    function updateTopicsUI() {
      if (!topicsToggle) return;
      var n = activeTopics.length;
      var label = topicsToggle.dataset.label || "Filter by topic";
      topicsToggle.textContent = n ? label + " (" + n + ")" : label;
      topicsToggle.classList.toggle("has-active", n > 0);
      topicsClear.hidden = n === 0;
    }
    topicButtons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        var topic = btn.dataset.topic;
        var i = activeTopics.indexOf(topic);
        if (i === -1) activeTopics.push(topic); else activeTopics.splice(i, 1);
        btn.setAttribute("aria-pressed", i === -1 ? "true" : "false");
        updateTopicsUI();
        render();
      });
    });
    if (topicsToggle) {
      topicsToggle.addEventListener("click", function () {
        var open = topicsPanel.hidden;
        topicsPanel.hidden = !open;
        topicsToggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
      topicsClear.addEventListener("click", function () {
        activeTopics = [];
        topicButtons.forEach(function (b) { b.setAttribute("aria-pressed", "false"); });
        updateTopicsUI();
        render();
      });
    }
    toggles.forEach(function (t) {
      t.addEventListener("click", function () {
        expanded = !expanded;
        render();
        // After collapsing, bring the top of the list back into view if it scrolled away.
        if (!expanded && root.getBoundingClientRect().top < 0) {
          root.scrollIntoView({ block: "start" });
        }
      });
    });

    var resizeTimer;
    window.addEventListener("resize", function () {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(updateClamps, 150);
    });

    // Allow links like /resources/?q=topology to open with a search filled in.
    var q = new URLSearchParams(window.location.search).get("q");
    if (q) search.value = q;

    // Simple lists (short ones) keep their controls hidden.
    if (!root.dataset.simple) {
      root.querySelectorAll(".flist-controls, .flist-status").forEach(function (el) {
        el.hidden = false;
      });
    }
    sort();
    render();
  }

  function initAll() {
    document.querySelectorAll(".flist").forEach(init);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAll);
  } else {
    initAll();
  }
})();
