---
title: "Metric Spaces"
description: "Metric spaces and continuous maps"
---
## Metrics

> [!def] Metric & Pseudometric
> A **metric** on a set $X$ is a function $d\colon X\times X\to[0,\infty)$ such that for all $x,y,z\in X$,
> 1. $d(x,x)=0$
> 2. $d(x,y) = 0$ implies $x=y$
> 3. $d(x,y) = d(y,x) \hspace{3 cm}$ (symmetry)
> 4. $d(x,z) \le d(x,y) + d(y,z). \quad \quad$ ($\triangle$-inequality)
> 
> If $d$ satisfies every axiom but the second, it is called a **pseudometric**.
^def-metric

> [!def] Metric Space
> A **metric space** is a pair $(X,d)$ comprised by a set $X$ and a [[#^def-metric|metric]] on $X$ $d : X \times X \to [0,\infty)$.
^def-metric-sp


> [!prop] Metric topology
> The open balls $B(x,r)=\{y : d(x,y)<r\}$ form a basis for a topology on $X$, in the sense of
> [[topological-spaces#^def-topology]].

^prop-metric-topology

> [!example]
> On $\mathbb{R}^n$, the Euclidean metric gives the usual topology, and by
> [[topological-spaces#^thm-composition]], compositions of continuous maps between Euclidean spaces are continuous.
