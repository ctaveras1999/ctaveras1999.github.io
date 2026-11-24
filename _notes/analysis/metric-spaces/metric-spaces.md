---
title: "Metric Spaces"
description: "Metric spaces and continuous maps"
---
## Metrics

> [!def] Metric space
> A **metric** on a set $X$ is a function $d\colon X\times X\to[0,\infty)$ such that for all $x,y,z\in X$,
> $d(x,y)=0$ if and only if $x=y$, $d(x,y)=d(y,x)$, and
> \begin{equation}
> d(x,z) \le d(x,y) + d(y,z). \label{eq:triangle}
> \end{equation}

^def-metric

The inequality \eqref{eq:triangle} is the **triangle inequality**.

> [!prop] Metric topology
> The open balls $B(x,r)=\{y : d(x,y)<r\}$ form a basis for a topology on $X$, in the sense of
> [[topological-spaces#^def-topology]].

^prop-metric-topology

> [!example]
> On $\mathbb{R}^n$, the Euclidean metric gives the usual topology, and by
> [[topological-spaces#^thm-composition]], compositions of continuous maps between Euclidean spaces are continuous.
