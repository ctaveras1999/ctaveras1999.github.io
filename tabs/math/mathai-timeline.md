---
title: "Math and AI Timeline"
permalink: "/math/mathai/timeline/"
layout: page
timeline: mathai
mathjax: true
description: "Moments in the story of AI and mathematics, newest first."
---
{%- comment -%}
  Each event: a ### heading, then {: date="YYYY-MM-DD" type="..."} on the next line, then a short
  summary; anything after <!-- more --> folds under "Read more". Optional: id="short-name" (the
  event's link, #short-name), follows="<id>" for a follow-up to an earlier event, time="HH:MM".
  Days are sorted newest first; events on the same day show in the order written here.
  Full instructions: _plugins/timeline.rb. The three newest also show on the Math and AI page.
{%- endcomment %}
Notable moments as AI and mathematics run into each other, newest first. For blog posts, essays,
talks, and more, see [the list]({{ '/math/mathai#the-list' | relative_url }}) on the
[Math and AI]({{ '/math/mathai' | relative_url }}) page.

### Stupid things I did
{: date="2026-11-23" type="Reaction" follows="alpoge-grh"}

Levent follows up on his now-notorious **[remark.pdf](https://alpo.ge/remark.pdf)** with a Twitter post titled **[Stupid things I did](https://x.com/__alpoge__/status/2124987173439209561)**, where he shares some regrets on his announcement of the proof.

<!-- more -->
There, he mentions that the 250,000+ page figure was exaggerated for comedic effect (i.e., "I find big number extremely hilarious") and used terminology like *[lengthmaxx](https://en.wikipedia.org/wiki/-maxxing)*, in stark contrast to the formality one usually expects from announcements/announcers of this sort. 

Somehow, Levent's response feels rather fitting for the times.
Perhaps his tweet will be seen as the inflection point from the romantic math of yesterday to the egoless math of the future that's been forecasted by many of today's leaders (with added [terminally-online](https://en.wikipedia.org/wiki/Extremely_online) flair).

### 100%-organic, Ph.D. Certified[^usda] Riemann Hypothesis Proof??
{: date="2026-11-20" type="Result" id="masullo-grh" time="12:00" follows="alpoge-grh"}
In case [Alpöge's sudden announcement](#alpoge-grh) wasn't dramatic enough, a few hours later, Ravi Vakil, 
one of the math community's undisputed leaders, made a [hurried announcement](https://math216.wordpress.com/2026/11/20/hurried-announcement-alessandro-masullo-grh/) in which he shares that **human** mathematician *Alessandro Maria Masullo* has a credible
claim to a proof of GRH, accessible [here](https://sites.google.com/view/tmotp/home?authuser=0).

<!-- more -->
Based on what's currently known about the Alpöge-Claude proof it appears that Masullo took a markedly different approach.
Given the hurried nature of the announcement, Masullo's proof, in its current premature state, had some gaps, which many were 
quick to point out so as to dismiss the attempt altogether.
In an act of great humanity and virtue, though, many in the community have dropped what they're doing and banded together 
to collectively digest and formalize Masullo's purported proof.
More on that [here](https://claude.ai/artifact/CtQyX8qfYAF822bgHJHHE3).

### Riemann ~~Hypothesis~~ Theorem?
{: date="2026-11-20" type="Result" id="alpoge-grh" time="08:00"}

Anthropic mathematician [Levent Alpöge](https://alpo.ge/) posts a [modest-looking four-page document](https://alpo.ge/remark.pdf)[^remark] on his website in which he claims to have proved the
[Generalized Riemann Hypothesis (GRH)](https://en.wikipedia.org/wiki/Generalized_Riemann_hypothesis) with the help of Claude.

<!-- more -->
As far as the proof goes, he chose to only share links of the lean formalization (17M+ lines of code) along with a brief timeline of the significant milestones, because in his words:

>It being obviously inappropriate to attempt to post some massive unreadable travesty of "slop", I decided to only present Lean.

This was accompanied by the intriguing footnote below

>I of course amused myself, and hit 250,000+ pages.[^troll]

At the time of writing, there have been several independent verifications of 
the Alpöge-Claude proof, which seems to suggest that the proof is correct; 
Andrew Sutherland explains his verification process [here](https://youtu.be/DHNFtd0yfds). 

In parallel, there has been a considerable effort to decode the proof from Lean to English,
which seems to have borne from preliminary fruit. 
For one, it seems like the proof employs [almost all](https://riemannhypothesissolved.com/) the machinery of classical and modern number theory.
A discussion of the machinery used in the proof can be found in Robin Zhang's [manuscript](https://www.ihes.fr/~rzhang/files/GRH%20note.pdf) accompanied by [his](https://youtu.be/tS8Ro66Zu1I) [discussions](https://youtu.be/bDtAO5fRuGE) with [Álvaro Lozano-Robledo](https://mathandcobb.org/)[^alvaro].


In case you want to learn more check out, 

[^remark]: Humorously, titled **remark.pdf**.
[^troll]: An exaggeration, as he later explained; see [the follow-up](#2026-11-23).
[^usda]: Not to be confused with [USDA certification](https://en.wikipedia.org/wiki/Organic_certification).
[^alvaro]: If you want to stay up to date with all news math and AI **from the perspective of a mathematician**, please check out Álvaro's work. His website is linked above, and you can find his YouTube [here](https://www.youtube.com/@mathandcobb/videos).