import bpy
import bmesh
import numpy as np
import mathutils

def compute_mesh_area(mesh):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    area = sum(f.calc_area() for f in bm.faces)
    bm.free()
    return area



def return_mesh_verts(mesh):
    return np.array([vert.co for vert in mesh.vertices])



def return_mesh_faces(mesh):
    return np.array([np.array(poly.vertices) for poly in mesh.polygons])



def return_mesh_edges(mesh):
    return np.array([np.array(edge.vertices) for edge in mesh.edges])



def compute_mesh_center(mesh):
    verts = return_mesh_verts(mesh)
    return np.mean(verts, axis=0)



def mesh_decenter(mesh):
    center = compute_mesh_center(mesh)
    for vert in mesh.vertices:
        vert.co = vert.co - mathutils.Vector(center)
    return mesh



def mesh_rescale(mesh, output_area=1):
    area = compute_mesh_area(mesh)
    scale = 1.0/np.sqrt(area)*np.sqrt(output_area)
    for vert in mesh.vertices:
        vert.co = vert.co*scale
    return mesh



def compute_mesh_boundingbox_naive(mesh):
    # compute the bound_box from the coordinates
    verts = return_mesh_verts(mesh)
    a = np.min(verts, axis=0)
    b = np.max(verts, axis=0)
    bbox_verts = [
        (a[0],a[1],a[2]),
        (a[0],b[1],a[2]),
        (b[0],b[1],a[2]),
        (b[0],a[1],a[2]),
        (a[0],a[1],b[2]),
        (a[0],b[1],b[2]),
        (b[0],b[1],b[2]),
        (b[0],a[1],b[2])]
        
    bbox_faces = [(0,1,2,3), (4,5,6,7), (0,4,5,1), (1,5,6,2), (2,6,7,3), (3,7,4,0)]
    
    return bbox_verts, bbox_faces

