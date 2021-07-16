import bpy
import bmesh
import sys
import argparse
from pathlib import Path




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


remove_all_meshes()
delete_all()
read_polygonshape_to_scene(mesh_dir, mesh_name, 2)
bpy.context.view_layer.objects.active = bpy.context.scene.objects[mesh_name]    
bpy.ops.export_scene.obj(filepath=save_dir+mesh_name+'.obj')



roof_name = mesh_name + '_roof'

remove_all_meshes()
delete_all()
read_polygonshape_to_scene(mesh_dir, roof_name, 2)
bpy.context.view_layer.objects.active = bpy.context.scene.objects[roof_name]    

my_path = Path(mesh_dir + mesh_name + '_texture_coord.txt')

# load the texture
if my_path.is_file():
    fid = open(mesh_dir + mesh_name + '_texture_coord.txt')
    lines=fid.readlines()
    uvmap = [np.fromstring(line, dtype=float, sep=',') for line in lines]

    mesh = bpy.context.active_object
    me = bpy.context.active_object.data

    uvlayer = me.uv_layers.new() # default naem and do_init
    me.uv_layers.active = uvlayer

    # add per-vertex texture coordinate
    for face in me.polygons:
        for vert_idx, loop_idx in zip(face.vertices, face.loop_indices):
            uvlayer.data[loop_idx].uv = (uvmap[vert_idx][0], uvmap[vert_idx][1]) 


bpy.ops.export_scene.obj(filepath=mesh_dir+roof_name+'.obj')
    



body_name = mesh_name + '_body'

# read the body
remove_all_meshes()
delete_all()
read_polygonshape_to_scene(mesh_dir, body_name, 2)
bpy.context.view_layer.objects.active = bpy.context.scene.objects[body_name]    
bpy.ops.export_scene.obj(filepath=save_dir+body_name+'.obj')


base_name = mesh_name + '_base'

# read the body
remove_all_meshes()
delete_all()
read_polygonshape_to_scene(mesh_dir, base_name, 2)
bpy.context.view_layer.objects.active = bpy.context.scene.objects[base_name]    
bpy.ops.export_scene.obj(filepath=save_dir+base_name+'.obj')