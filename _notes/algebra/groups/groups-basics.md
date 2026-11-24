---
title: "Group Fundamentals"
description: "Groups, their homomorphisms, and basic results."
---
## Metrics

> [!def] Group
> A **group** is a pair $(G, *)$ comprised of a set $G$ and a binary operation $*: G \times G \to G$ satisfying the following axioms:
> 1. there exists an identity element $e \in G$ satisfying $g * e = e * g = e$ for all $g \in G$;
> 2. $*$ is closed under inverses; i.e. for all $g \in G$ there exists $h \in G$ such that $g * h = h * g = e$;
> 3. $*$ is associative.
^def-group

> [!def] Group Homomorphism
> A *group homomorphism* between groups $(G, *)$ and $(H,\cdot)$ is a map $\vphi : G \to H$ satisfying
> $$\vphi(a * b) = \vphi(a) \cdot \vphi(b) \quad \text{ for all } a, b \in G.$$