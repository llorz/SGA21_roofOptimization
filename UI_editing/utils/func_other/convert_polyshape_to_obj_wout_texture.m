function  [] = convert_polyshape_to_obj_wout_texture(M, mesh_name, save_dir)
M.verts(:,1:2) = M.verts(:,1:2) - mean(M.verts(:,1:2));
% we separate the roof and the body
M_body = M;
M_roof = M;

ind_roof = find(M.face_labels == 1);
ind_body = setdiff(1:length(M.face_labels), ind_roof);

M_body.faces(ind_roof) = [];
M_body.face_labels(ind_roof) = [];

M_roof.faces(ind_body) = [];
M_roof.face_labels(ind_body) = [];

my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_body);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M);

matlab_process_roof_polyshape(save_dir, mesh_name, save_dir);
end
