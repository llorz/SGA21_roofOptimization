clc; clf; cla;
addpath(genpath('utils/'));
%%
dt_dir = '/Users/renj/Renj/Project/PROJ2020_roof_construction/data/';
res_dir = '/Users/renj/Renj/Project/PROJ2020_roof_construction/data/label_jing/';
all_meshes = dir([dt_dir, 'image/*.jpg']);
ifile = 3;
mesh_name = all_meshes(ifile).name(1:end-4);
V = dlmread([res_dir, mesh_name,'.verts']);
F_tmp = dlmread([res_dir, mesh_name, '.faces']);
F = cell(size(F_tmp,1),1);
for i = 1:size(F_tmp,1)
    tmp = F_tmp(i,:);
    tmp = tmp(tmp > 0);
    F{i}  = tmp(:);
end

%%
obj = RoofGraph(V, F);

obj = reindex_roofgraph(obj);
[obj,R] = axis_align_roof_graph(obj);

obj = regularize_outline_edges(obj);
obj.V = obj.V*R';

figure(1); clc; plot(obj)
%%
para.eps_ortho = 1e-3;
para.lambda_minEdgeLen = 0;
para.minEdgeLen = 0.5;
para.lambda_ini = 1e-6;
obj = optimize_2D_feasible_roofgraph_close2ini(obj, para);

figure(2); clf; plot(obj2);

roof_height = 50; 
body_height = 100;
X1 = construct_3D_roof_from_straight_skeleton(obj.V, obj.F, obj.vid_roof, roof_height);
M = construct_building(X1, obj.F, body_height);

figure(3); clf; 
plot_building(M.verts, M.faces)