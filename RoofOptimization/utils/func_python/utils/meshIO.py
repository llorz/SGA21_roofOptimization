import bpy
import numpy as np
import imp

import utils.meshHelper
imp.reload(utils.meshHelper)
from utils.meshHelper import *


def read_obj_to_scene(mesh_dir, mesh_name):
    bpy.ops.import_scene.obj(
        filepath= mesh_dir + mesh_name + '.obj', 
        filter_glob="*.obj;*.mtl", 
        use_edges=True, 
        use_smooth_groups=True, 
        use_split_objects=True, 
        use_split_groups=False, 
        use_groups_as_vgroups=False, 
        use_image_search=True, 
        split_mode='ON', 
        #global_clight_size=0.0,
        axis_forward='Y', 
        axis_up='Z')
        
    mesh = bpy.context.scene.objects[mesh_name].data    
    return mesh



def save_polygon_mesh(shape_name, write_dir):
    
    mesh = bpy.data.objects[shape_name].data
    
    verts = return_mesh_verts(mesh)
    faces = return_mesh_faces(mesh)
    edges = return_mesh_edges(mesh)

    write_polygon_shape(write_dir + shape_name + '.polyshape', verts, faces, edges)



def write_polygon_shape(write_dir, verts, faces, edges):
    fid = open(write_dir, "w")
    
    fid.write("# Number of verts: %d\n"  % len(verts))
    fid.write("# Number of faces: %d\n"  % len(faces))
    fid.write("# Number of edges: %d\n"  % len(edges))
    
    np.savetxt(fid, verts, fmt='%1.12f',delimiter=',')
    np.savetxt(fid, faces, fmt='%i',delimiter=',')
    np.savetxt(fid, edges, fmt='%i',delimiter=',')
    
    fid.close()
    
    

def get_number_from_str(str):
    a = [int(s) for s in str.split() if s.isdigit()]
    return a[0]





def read_polygon_shape(mesh_dir, mesh_name, type=1):
    # read from 
    if type == 1:
        fid = open(mesh_dir + mesh_name + '.polyshape')
        lines=fid.readlines()
        
        nv = get_number_from_str(lines[0])
        nf = get_number_from_str(lines[1])
        ne = get_number_from_str(lines[2])
        
        verts = [np.fromstring(line, dtype=float, sep=',') for line in lines[3:3+nv]]
        faces = [np.fromstring(line, dtype=int, sep=',') for line in lines[3+nv:3+nv+nf]]
        edges = [np.fromstring(line, dtype=int, sep=',') for line in lines[3+nv+nf:3+nv+nf+ne]]
        return verts, faces, edges
    else: # no edge information, with label information
        fid = open(mesh_dir + mesh_name + '.polyshape')
        lines=fid.readlines()
        
        nv = get_number_from_str(lines[0])
        nf = get_number_from_str(lines[1])
        
        verts = [np.fromstring(line, dtype=float, sep=',') for line in lines[2:2+nv]]
        faces = [np.fromstring(line, dtype=int, sep=',') for line in lines[2+nv:2+nv+nf]]
        faces = [f[0:-1]-1 for f in faces]
        
        return verts, faces
 
 


def construct_object_from_mesh_to_scene(verts, faces, mesh_name):
    mesh = bpy.data.meshes.new(mesh_name)
    mesh.from_pydata(verts, [], faces)
    mesh.update(calc_edges=True)
    object = bpy.data.objects.new(mesh_name, mesh)
    bpy.context.scene.collection.objects.link(object)


def read_polygonshape_to_scene(mesh_dir, mesh_name, type=1):
    verts, faces = read_polygon_shape(mesh_dir, mesh_name, type)
    construct_object_from_mesh_to_scene(verts, faces, mesh_name)
    



