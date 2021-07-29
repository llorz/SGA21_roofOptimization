# Roof Optimization
In this project, we propose a novel and flexible *roof modeling* approach that can be used for constructing planar 3D polygon roof meshes. 
Our method uses a *roof graph* structure to encode roof topology and enforces the roof validity by optimization a simple but effective *planarity metric*. 

## Usage
1. **Roof graph specification**: one can use the UIs [here](https://github.com/llorz/SGA21_roofOptimization/tree/main/UI_annotation) to specify the roof topology as a primal graph (consisting roof vertices ```V``` and faces ```F```), or a dual graph (consisting roof outline vertices ```VO```, and face adjacency matrix ```A```).
2. **Roof optimization**: we then solve for a *valid 3D embedding* for the roof, such that each 3D roof face is planar. See the [function](https://github.com/llorz/SGA21_roofOptimization/blob/main/RoofOptimization/fig16_recon/reconstruct_3D_roof.m) ```RoofOptimization/fig16_recon/reconstruct_3D_roof.m```, in which the function ```energy_smallest_eigenval(X, F)``` gives a *planarity* metric. 
3. [Blender](https://www.blender.org/) is used to convert the reconstructed polygonal roof (saved as ```.polyshape```) into ```.obj``` file. See ```/RoofOptimization/utils/func_python/matlab_process_roof_polyshape(_windows).m```. To make it work, you need to update the blender and project path in ```/RoofOptimization/utils/func_python/blender_path(_win).txt```

## Baseline methods
### Straight Skeleton based methods:
- Straight Skeleton in CGAL [[code]](https://doc.cgal.org/latest/Straight_skeleton_2/index.html)
- Weighted Straight Skeleton in Java [[code]](https://github.com/twak/campskeleton)
### Commercial software




## setup


## References
1. "A Novel Type of Skeleton for Polygons", *Oswin Aichholzer, Franz Aurenhammer, David Alberts, Bernd Gartner*, 1996. [[paper]](https://www.researchgate.net/publication/220349949_A_Novel_Type_of_Skeleton_for_Polygons)
2. "Straight Skeleton Implementation", *Petr Felkel and Stepan Obdrzalek*, 1998. [[paper]](http://www.dma.fi.upm.es/personal/mabellanas/tfcs/skeleton/html/documentacion/Straight%20Skeletons%20Implementation.pdf)
3. "Computing Straight Skeletons and Motocycle Graphs: Theory and Practice", *Stefan Huber*, 2011. [[PhD thesis]](https://www.sthu.org/research/publications/files/phdthesis.pdf)
4. "Interactive Architectural Modeling with Procedural Extrusions", *Tom Kelly and Peter Wonka*, 2011. [[paper]](http://www.twak.co.uk/2011/04/interactive-architectural-modeling-with.html)
