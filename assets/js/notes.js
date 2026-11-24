// Hover previews for references in math notes (links made by _plugins/academic_notes.rb).
// Pointing at a reference such as "Theorem 1.3" (or focusing it with the keyboard) shows that
// block in a small card; references to other notes fetch that note in the background. The
// card stays open while the pointer is over it; Escape or moving away closes it.
// Only on devices with a mouse or trackpad; on touch screens references are plain links.
// Long "Referenced in" lists start collapsed, with a "Show all" button (on every device).
(function () {
  "use strict";
  document.querySelectorAll(".backrefs-toggle").forEach(function (btn) {
    var list = btn.parentNode, label = btn.textContent;
    list.classList.add("is-collapsed");
    btn.hidden = false;
    btn.setAttribute("aria-expanded", "false");
    btn.addEventListener("click", function () {
      var open = list.classList.toggle("is-collapsed") === false;
      btn.textContent = open ? "Show fewer" : label;
      btn.setAttribute("aria-expanded", open ? "true" : "false");
    });
  });
})();

(function () {
  "use strict";
  if (!window.matchMedia || !matchMedia("(hover: hover)").matches) return;

  var pages = {};        // url -> Promise of a parsed document
  var card = null, current = null, showTimer = null, hideTimer = null;

  function page(path) {
    if (!pages[path]) {
      pages[path] = fetch(path)
        .then(function (r) { return r.ok ? r.text() : Promise.reject(r.status); })
        .then(function (html) { return new DOMParser().parseFromString(html, "text/html"); });
    }
    return pages[path];
  }

  function hide() {
    clearTimeout(showTimer);
    if (card) card.remove();
    card = null;
    current = null;
  }
  function hideSoon() {
    clearTimeout(hideTimer);
    hideTimer = setTimeout(hide, 200);
  }

  function place(link) {
    if (!card) return;
    var r = link.getBoundingClientRect(), w = card.offsetWidth, h = card.offsetHeight;
    var left = Math.min(Math.max(8, r.left), window.innerWidth - w - 8);
    var top = r.bottom + 6;
    if (top + h > window.innerHeight - 8 && r.top - h - 6 > 8) top = r.top - h - 6; // flip above
    card.style.left = left + window.scrollX + "px";
    card.style.top = top + window.scrollY + "px";
  }

  function show(link) {
    var url = new URL(link.href, location.href);
    var id = decodeURIComponent(url.hash.slice(1));
    if (!id) return;
    var samePage = url.pathname === location.pathname;
    current = link;
    (samePage ? Promise.resolve(document) : page(url.pathname)).then(function (doc) {
      if (current !== link) return;          // the pointer moved on meanwhile
      var target = doc.getElementById(id);
      if (!target) return;
      if (card) card.remove();
      card = document.createElement("div");
      card.className = "xref-card";
      card.setAttribute("role", "tooltip");
      var copy = target.cloneNode(true);
      copy.removeAttribute("id");
      copy.querySelectorAll("[id]").forEach(function (n) { n.removeAttribute("id"); });
      copy.querySelectorAll(".env-backrefs").forEach(function (n) { n.remove(); });
      if (copy.tagName === "DETAILS") copy.open = true;
      card.appendChild(copy);
      card.addEventListener("mouseenter", function () { clearTimeout(hideTimer); });
      card.addEventListener("mouseleave", hideSoon);
      document.body.appendChild(card);
      place(link);
      // Math from another page arrives as LaTeX; typeset it (math on this page already is)
      if (!samePage && window.MathJax && MathJax.typesetPromise) {
        MathJax.typesetPromise([card]).then(function () { place(link); }).catch(function () {});
      }
    }).catch(function () {});
  }

  function refFrom(e) {
    return e.target.closest && e.target.closest("a.xref");
  }
  document.addEventListener("mouseover", function (e) {
    var a = refFrom(e);
    if (!a) return;
    clearTimeout(hideTimer);
    if (a === current) return;
    clearTimeout(showTimer);
    showTimer = setTimeout(function () { show(a); }, 150);
  });
  document.addEventListener("mouseout", function (e) {
    if (refFrom(e)) { clearTimeout(showTimer); hideSoon(); }
  });
  document.addEventListener("focusin", function (e) { var a = refFrom(e); if (a) show(a); });
  document.addEventListener("focusout", function (e) { if (refFrom(e)) hideSoon(); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape") hide(); });
  window.addEventListener("scroll", function () { if (card && current) place(current); }, { passive: true });
})();
