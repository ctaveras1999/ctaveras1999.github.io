---
title: "Topological Spaces, Continuous Maps, and Compactness"
description: "Open sets, Continuity, and Compactness."
---

## Topological spaces

> [!def] Topological space
> A **topology** on a set $X$ is a collection $\tau$ of subsets of $X$ containing $\varnothing$ and $X$,
> closed under arbitrary unions and finite intersections. The sets in $\tau$ are called **open**.

^def-topology

> [!def] Continuity
> A map $f\colon X \to Y$ between topological spaces is **continuous** if $f^{-1}(U)$ is open in $X$
> for every open set $U \subseteq Y$.

^def-continuity


> [!thm] Composition
> If $f\colon X\to Y$ and $g\colon Y\to Z$ are continuous, then so is $g\circ f$.

^thm-composition

> [!proof] [[#^thm-composition]]
> For $U \subseteq Z$ open, $(g\circ f)^{-1}(U) = f^{-1}\big(g^{-1}(U)\big)$. By [[#^def-continuity]],
> $g^{-1}(U)$ is open in $Y$, and hence $f^{-1}(g^{-1}(U))$ is open in $X$.

## Compactness

> [!def] Compactness
> A space $X$ is **compact** if every open cover of $X$ has a finite subcover.

^def-compact

> [!thm] Continuous images of compact sets
> If $f\colon X \to Y$ is [[#^def-continuity|continuous]] and $X$ is compact, then $f(X)$ is compact.

^thm-image-compact

> [!remark]
> Compactness is a topological property: by [[#^thm-image-compact]], it is preserved by homeomorphisms.
