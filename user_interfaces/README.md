# MapTree: Recovering Multiple Solutions in the Space of Maps
This is an example code for the paper "MapTree: Recovering Multiple Solutions in the Space of Maps" by Jing Ren, Simone Melzi, Maks Ovsjanikov, and Peter Wonka.

In this paper we propose an approach for computing **multiple** high-quality near-isometric maps between a pair of 3D shapes. Our method is fully automatic and does not rely on user-provided landmarks or descriptors. This allows us to analyze the full space of maps and extract multiple diverse and accurate solutions, rather than optimizing for a single optimal correspondence as done in previous approaches. 

<p align="center">
  <img align="center"  src="/figs/teaser_gravgen_v2.png", width=800>
</p>

Main Functions
--------------------
```
[fMapTree] = explore_map_space(S1, S2, para)

% Input:
%   S1: The LB basis of the source shape S1
%   S2: The LB basis of the target shape S2
%   para: a structure stores the following parameters
%     num_samples_on_shape: intermediate functional maps are computed on a subset of vertices
%     num_eigs: num eigenfunctions to compute (= stop_dim)
%     thres_lapcomm: threshold for the Laplacian Commutativity
%     thres_ortho: threshold for the orthogonality
%     thres_fmap_dist: if the normalized distance between two fmaps is smaller than this threshold, we assume these two maps are equivalent after applying zoomout
%     stop_dim: the maximum depth of the tree
%     max_width: the largest width of the tree at each depth (to speed up with expanding the tree too wide)
%     num_maps_keep: the number of maps that are selected from the map tree
%     thres_repeating_eigs: threshold for repeating eigenvalues detection
%
% Output:
%   fMapTree: a tree structure that contains multiple (organized) maps
```


Comments
-------------------------
- The script ```eg1_selfSymm.m``` shows how to find multiple self-symmetric maps on a single shape.
- The script ```eg2_shapePair.m``` shows how to find multiple high-quality maps between a shape pair.
- Please let us know (jing.ren@kaust.edu.sa) if you have any question regarding the algorithms/paper ʕ•ﻌ•ʔ or you find any bugs in the code ԅ(¯﹃¯ԅ)


[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

This work is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License](http://creativecommons.org/licenses/by-nc/4.0/). For any commercial uses or derivatives, please contact us (jing.ren@kaust.edu.sa, peter.wonka@kaust.edu.sa, maks@lix.polytechnique.fr).
