---
title: "Resources"
permalink: "/resources/"
layout: page
---
<nav class="toc" aria-label="On this page">
<a href="#learning-materials">Learning Materials</a>
<a href="#for-undergraduates">For Undergraduates</a>
<a href="#for-graduate-students">For Graduate Students</a>
<a href="#for-researchers">For Researchers</a>
<a href="#math-media">Math Media</a>
</nav>

{% assign res = site.data.resources.other %}

## Learning Materials
### Some Folks with Good (Free!) Online Learning Materials
Below is a growing list of academics who've posted useful resources online 
including full university courses, notes/recordings, problem sets, textbooks, 
insights, and more.
To support them, you should read their work (research) and share it with others, if possible.

I tried to include a broad range of topics across pure and applied math, 
computer science and (mostly electrical) engineering.
Please reach out to me (via email) if you have suggestions on others to add![^suggestions] 
For those on the list, thank you for making these resources freely accessible to us all![^corrections]

The list is ordered randomly by default.
You can choose to sort by last name or affiliation and also search by topic.

{% include filterable-list.html data=site.data.resources.learning_people id="learning" limit=5 %}

### More Places to Learn
{% assign items = res | where: "section", "learning" %}
{% include filterable-list.html data=items id="learning-more" simple=true limit=4 topics_open=true topic_order="data" %}

## For Undergraduates
Research experiences (REUs) and scholarships.
{% assign items = res | where: "section", "undergrad" %}
{% include filterable-list.html data=items id="undergrad" simple=true limit=5 topics_open=true topic_order="data" %}

## For Graduate Students
Sample qualifying exams, programs and workshops to apply to, and fellowships.
{% assign items = res | where: "section", "grad" %}
{% include filterable-list.html data=items id="grad" simple=true limit=5 topics_open=true topic_order="data" %}

## For Researchers
Recorded talks and lecture series.
{% assign items = res | where: "section", "research" %}
{% include filterable-list.html data=items id="research" simple=true limit=4 %}

## Math Media
Videos and blogs, for fun and inspiration.
{% assign items = res | where: "section", "media" %}
{% include filterable-list.html data=items id="media" simple=true limit=4 %}

[^suggestions]: That includes you, if you have something to share with the rest of us :) .
[^corrections]: If you're on this list and either don't want to be or you see erroneous information, please let me know! 