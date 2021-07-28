import bpy
import bmesh
import sys
import argparse


proj_dir = '/Users/renj/Renj/Project/PROJ2020_roof_construction/func_python/'

if not proj_dir in sys.path:
    sys.path.append(proj_dir)
    
import include
import imp
imp.reload(include) 
from include import *


remove_all_meshes()
delete_all()



if '--' in sys.argv:
    argv = sys.argv[sys.argv.index('--') + 1:]
    parser = argparse.ArgumentParser()
    parser.add_argument('-s1', '--mesh_dir', type=str, default='')
    parser.add_argument('-s2', '--mesh_name', type=str, default='')
    parser.add_argument('-s3', '--save_dir', type=str, default='')
    args = parser.parse_known_args(argv)[0]

mesh_name = args.mesh_name
mesh_dir = args.mesh_dir
save_dir = args.save_dir

read_polygonshape_to_scene(mesh_dir, mesh_name, 2)
bpy.context.view_layer.objects.active = bpy.context.scene.objects[mesh_name]    
bpy.ops.object.modifier_apply(apply_as='DATA', modifier="Triangulate")
bpy.ops.export_scene.obj(filepath=save_dir+mesh_name+'.obj')
