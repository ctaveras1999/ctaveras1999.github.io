---
title: "Academic"
permalink: "/academic/"
layout: page
---
<nav class="toc" aria-label="On this page">
<a href="#education">Education</a>
<a href="#research-interests">Research Interests</a>
<a href="#publications">Publications</a>
<a href="#teaching">Teaching</a>
<a href="#awards-and-fellowships">Awards</a>
<a href="#conferences-and-workshops">Conferences</a>
<a href="#other-experience">Other</a>
<a href="#cv">CV</a>
</nav>

## Education
{% include cv-list.html items=site.data.cv.education %}

## Research Interests
{{ site.data.cv.profile.research_interests | join: ", " }}.

## Publications
{% include pubs.html %}
See also [Google Scholar](https://scholar.google.com/citations?user=sw4tzEoAAAAJ&hl=en).

## Teaching
{% include cv-list.html items=site.data.cv.teaching %}

## Awards and Fellowships
{% include cv-list.html items=site.data.cv.awards %}

## Conferences and Workshops
{% include cv-list.html items=site.data.cv.events %}

## Other Experience
{% include cv-list.html items=site.data.cv.other %}

## CV
<div class="cv-card">
  <a class="cv-thumb" href="{{ '/media/docs/cv.pdf' | relative_url }}?v={{ site.data.cv_build.version }}" aria-label="Open my CV (PDF)"><img src="{{ '/media/docs/cv-preview.jpg' | relative_url }}?v={{ site.data.cv_build.version }}" alt="Preview of the first page of my CV" width="400" height="518" loading="lazy"></a>
  <div class="cv-card-body">
    <p>Everything above is also in my CV, as a PDF to read, print, or share.</p>
    <div class="cv-actions">
      <a class="cv-button" href="{{ '/media/docs/cv.pdf' | relative_url }}?v={{ site.data.cv_build.version }}">View PDF</a>
      <a class="cv-button" href="{{ '/media/docs/cv.pdf' | relative_url }}?v={{ site.data.cv_build.version }}" download="Carlos-Taveras-CV.pdf">Download</a>
    </div>
    <p class="cv-updated">Last updated {{ site.data.cv_build.updated }} · {{ site.data.cv_build.pages }} pages</p>
  </div>
</div>
