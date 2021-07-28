import bpy
import bmesh

def delete_all():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete() 

def remove_all_meshes():
    for mesh in bpy.data.meshes:
        bpy.data.meshes.remove(mesh)
    
def remove_all_collections():
    for c in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.unlink(c)
    
    for c in bpy.data.collections:
        if not c.users:
            bpy.data.collections.remove(c)
    

def view3d_find(return_area = False ):
    # returns first 3d view, normally we get from context
    for area in bpy.context.window.screen.areas:
        if area.type == 'VIEW_3D':
            v3d = area.spaces[0]
            rv3d = v3d.region_3d
            for region in area.regions:
                if region.type == 'WINDOW':
                    if return_area: return region, rv3d, v3d, area
                    return region, rv3d, v3d
    return None, None



def update_lookup_table(bm):
    # once apply some modifications to the mesh, update the lookup table
    if hasattr(bm.verts, "ensure_lookup_table"): 
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()   
        bm.faces.ensure_lookup_table()