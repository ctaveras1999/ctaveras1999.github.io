// Open links to other websites, and PDFs, in a new tab.
// Links within this site (menu, footnotes, page sections) and email links are left alone.
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("a[href]").forEach(function (a) {
    var url = new URL(a.href, window.location.href);
    var isWeb = url.protocol === "http:" || url.protocol === "https:";
    var isExternal = isWeb && url.host !== window.location.host;
    var isPdf = /\.pdf$/i.test(url.pathname);
    if (isExternal || isPdf) {
      a.target = "_blank";
      a.rel = "noopener noreferrer";
    }
  });
});
