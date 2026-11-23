// Tag filtering for the post lists on the Blog and Math pages (_includes/page-list.html).
// Clicking a tag shows only posts with that tag; clicking it again (or "Show all") shows
// everything. The active tag is kept in the address (?tag=...), so links like /blog/?tag=Personal
// open already filtered. Without JavaScript every post stays visible.
(function () {
  "use strict";

  function init(wrap) {
    var items = Array.prototype.slice.call(wrap.querySelectorAll(".page-list > li"));
    var buttons = Array.prototype.slice.call(wrap.querySelectorAll(".flist-tag[data-tag]"));
    var status = wrap.querySelector(".page-list-filter");
    var statusText = wrap.querySelector(".page-list-filter-text");
    var clear = wrap.querySelector(".page-list-clear");
    var active = null;

    function apply() {
      var shown = 0;
      items.forEach(function (li) {
        var tags = (li.dataset.tags || "").split("|");
        var visible = !active || tags.indexOf(active) !== -1;
        li.hidden = !visible;
        if (visible) shown++;
      });
      buttons.forEach(function (b) {
        b.setAttribute("aria-pressed", b.dataset.tag === active ? "true" : "false");
      });
      if (status) {
        status.hidden = !active;
        statusText.textContent = active
          ? (shown === 1 ? "1 post" : shown + " posts") + " tagged “" + active + "”"
          : "";
      }
      // Keep the filter in the address without adding a history entry for every click.
      var url = new URL(window.location.href);
      if (active) url.searchParams.set("tag", active); else url.searchParams.delete("tag");
      window.history.replaceState(null, "", url);
    }

    buttons.forEach(function (b) {
      b.addEventListener("click", function () {
        active = active === b.dataset.tag ? null : b.dataset.tag;
        apply();
      });
    });
    if (clear) clear.addEventListener("click", function () { active = null; apply(); });

    var fromUrl = new URLSearchParams(window.location.search).get("tag");
    if (fromUrl && buttons.some(function (b) { return b.dataset.tag === fromUrl; })) {
      active = fromUrl;
      apply();
    }
  }

  function initAll() {
    document.querySelectorAll(".page-list-wrap").forEach(init);
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAll);
  } else {
    initAll();
  }
})();
