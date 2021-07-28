import bpy
import bmesh

def deselect_all_faces_edges_vtxs(bm):
    for edge in bm.edges:
        edge.select = False
    for vert in bm.verts:
        vert.select = False
    for face in bm.faces:
        face.select = False

def update_lookup_table(bm):
    # once apply some modifications to the mesh, update the lookup table
    if hasattr(bm.verts, "ensure_lookup_table"): 
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()   
        bm.faces.ensure_lookup_table()


def select_multiple_edges(bm, edge_id):
    # select multiple edges
    if isinstance(edge_id, int):
        if edge_id >= len(bm.edges):
            print('Edge index = '+ str(edge_id) + ' out of range (' + str(len(bm.edges)) + ')')
            return -1
        else:
            bm.edges[edge_id].select = True
    elif isinstance(edge_id, tuple) or isinstance(edge_id, list):
        for i in edge_id:
            if i < len(bm.edges):
                bm.edges[i].select = True    
            else:
                print('Edge index = '+ str(i) + ' out of range (' + str(len(bm.edges)) + ')')
    else:
        print('Unsuported edge index set')
        return -1
    
    update_lookup_table(bm)


    
def select_multiple_faces(bm, face_id):
    if isinstance(face_id, int):
        if face_id >= len(bm.faces):
            print('Face index = ' + str(face_id) + ' out of range (' + str(len(bm.faces)) + ')')
            return -1
        else:
            bm.faces[face_id].select = True
    elif isinstance(face_id, tuple) or isinstance(face_id, list):
        for i in face_id:
            if i < len(bm.faces):
                bm.faces[i].select = True   
            else:
                print('Face index = ' + str(i) + ' out of range (' + str(len(bm.faces)) + ')') 
    else:
        print('Unsuported face index set')
        return -1
    
    update_lookup_table(bm)



def select_multiple_verts(bm, vtx_id):
    if isinstance(vtx_id, int):
        if vtx_id >= len(bm.verts):
            print('Vertex index = ' + str(vtx_id) + ' out of range (' + str(len(bm.verts)) + ')')
            return -1
        else:
            bm.verts[vtx_id].select = True
    elif isinstance(vtx_id, tuple) or isinstance(vtx_id, list):
        for i in vtx_id:
            if i < len(bm.verts):
                bm.verts[i].select = True
            else:
                print('Vertex index = ' + str(i) + ' out of range (' + str(len(bm.verts)) + ')')    
                return -1
    else:
        print('Unsuported vertex index set')
        return -1
    
    update_lookup_table(bm)
        
#--------------------------------------------------------------------------
#-------------------------- Translation Operators -------------------------
#--------------------------------------------------------------------------



def translate_op(value, constraint_axis):
    bpy.ops.transform.translate(
    value=value, 
    orient_type='GLOBAL', 
    orient_matrix=((1, 0, 0), (0, 1, 0), (0, 0, 1)), 
    orient_matrix_type='GLOBAL', 
    constraint_axis=constraint_axis, 
    mirror=True, 
    proportional='DISABLED', 
    proportional_edit_falloff='SMOOTH', 
    proportional_size=1, 
    release_confirm=True)
    

    
def edge_translate(bm, edge_id, edge_trans_direction, constraint_axis):
    # deselect all the edges except the specified one
    update_lookup_table(bm)
    deselect_all_faces_edges_vtxs(bm)    
    select_multiple_edges(bm, edge_id)
    translate_op(edge_trans_direction, constraint_axis)
    deselect_all_faces_edges_vtxs(bm)
    update_lookup_table(bm)
    
        
    
    
def vtx_translate(bm, vtx_id, vtx_trans_direction, constraint_axis):
    update_lookup_table(bm)
    deselect_all_faces_edges_vtxs(bm)
    select_multiple_verts(bm, vtx_id)
    translate_op(vtx_trans_direction, constraint_axis)
    deselect_all_faces_edges_vtxs(bm)
    update_lookup_table(bm)


    

def face_translate(bm, face_id, face_trans_direction, constraint_axis):   
    update_lookup_table(bm)
    deselect_all_faces_edges_vtxs(bm)
    select_multiple_faces(bm)
    translate_op(face_trans_direction, constraint_axis)
    deselect_all_faces_edges_vtxs(bm)
    update_lookup_table(bm)
        


#--------------------------------------------------------------------------
#------------------------- Face Extrusion Operator ------------------------
#--------------------------------------------------------------------------

def face_extrusion(bm, face_id, extrusion_scale):
    update_lookup_table(bm)
    deselect_all_faces_edges_vtxs(bm)
    select_multiple_faces(bm, face_id)

    bpy.ops.mesh.extrude_faces_move(
        MESH_OT_extrude_faces_indiv={"mirror":False}, 
        TRANSFORM_OT_shrink_fatten={
            "value":extrusion_scale, 
            "use_even_offset":True, 
            "mirror":False, 
            "proportional":'DISABLED', 
            "proportional_edit_falloff":'SMOOTH', 
            "proportional_size":1, 
            "snap":False, 
            "snap_target":'CLOSEST', 
            "snap_point":(0, 0, 0), 
            "snap_align":False, 
            "snap_normal":(0, 0, 0), 
            "release_confirm":False})   
        
    deselect_all_faces_edges_vtxs(bm)        
    update_lookup_table(bm)


#--------------------------------------------------------------------------
#------------------------- LoopCut along an edge  -------------------------
#--------------------------------------------------------------------------

def loopcut_slide(edge_ind, val, override):
    bpy.ops.mesh.loopcut_slide(
    override, 
    MESH_OT_loopcut={
        "number_cuts":1, 
        "smoothness":0, 
        "falloff":'INVERSE_SQUARE', 
        "object_index":0, 
        "edge_index":edge_ind, 
        "mesh_select_mode_init":(True, False, False)}, 
    TRANSFORM_OT_edge_slide={
        "value":val, 
        "single_side":False, 
        "use_even":False, 
        "flipped":False, 
        "use_clamp":True, 
        "mirror":True, 
        "snap":False, 
        "snap_target":'CLOSEST', 
        "snap_point":(0, 0, 0), 
        "snap_align":False, 
        "snap_normal":(0, 0, 0), 
        "correct_uv":True, 
        "release_confirm":False, 
        "use_accurate":False})
    
