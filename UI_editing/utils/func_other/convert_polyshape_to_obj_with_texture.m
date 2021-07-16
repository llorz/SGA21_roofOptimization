function  [M, X1, I] = convert_polyshape_to_obj_with_texture(mesh_dir, mesh_name, save_dir)
M = my_read_polygon_shapes([mesh_dir, 'res_building/'], mesh_name);
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

%% load the texture
X1 = dlmread([mesh_dir, 'dt_roof_label/', mesh_name,'.verts']);
I = imread([mesh_dir, 'dt_roof_image/', mesh_name,'.jpg']);
imwrite(I,[save_dir, mesh_name, '.jpg'],'jpeg')


num = size(X1,1);
S_vt = zeros(num,2);

S_vt(:,2) = 1-X1(:,2)/size(I,1);
S_vt(:,1) = X1(:,1)/size(I,2);
%%

dlmwrite([save_dir ,mesh_name, '_texture_coord.txt'], S_vt);
matlab_process_roof_polyshape(save_dir, mesh_name, save_dir);
end
