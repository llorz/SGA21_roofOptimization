clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')

lambda = 1e-6;
roof_height = 200;
body_height = 150;

file_name = 'nagoya';

dt_dir = ['./data/',file_name,'/'];
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end
%% read and construct the roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);

% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf; IfPlotShowLabel = false;
plot(obj);

obj = regularize_outline_edges(obj);
figure(2); clf;
plot(obj); title('regularize the outlines')
%%
% we can specify that some vertices should be in a similar height
% this is done by penalizing the variance of the vertex heights
vid_z_var = {[7,10,16,18], ...
    [25,27,49,51],...
    [60,63,66],...
    [37,39,42,60],...
    [30,32,42,44], ...
    [73,75,91,99],...
    [102,104,112, 114],...
    [67,69,83,81]};


% the rough height for each group of vertices
vid_z_height = [120,120,100,100,100,100,150,100];
%%
vid_xy = obj.vid_roof;
vid_z = obj.vid_roof;

X0 = [obj.V, zeros(obj.nv,1)];
X0(vid_z, 3) = roof_height;
for i = 1:length(vid_z_var)
X0(vid_z_var{i},3) = vid_z_height(i);
end

X1 = construct_3D_roof_nagoya(obj.V,  obj.F, vid_xy, vid_z, vid_z_var, lambda, X0);

figure(3);  clf;
plot_building(X1, F)
%% refine some vertices
X2  = X1;
vid_var = [];

mod_vid = 21;
X2(mod_vid,:) = X2(mod_vid,:) - [200,0,100];
tmp = find_local_affected_vertex(obj, mod_vid);
vid_var = [vid_var; tmp(:); mod_vid];

mod_vid = 106;
X2(mod_vid,:) = X2(mod_vid,:) - [0,200,100];
tmp = find_local_affected_vertex(obj, mod_vid);
vid_var = [vid_var; tmp(:); mod_vid];

mod_vid = 55;
X2(mod_vid,:) = X2(mod_vid,:) - [0,0,200];
tmp = find_local_affected_vertex(obj, mod_vid);
vid_var = [vid_var; tmp(:); mod_vid];


X3 = construct_3D_roof_nagoya(X2, obj.F, vid_var, vid_var, vid_z_var, lambda, X2);
figure(3);  clf;
plot_building(X3, F)
%%
err0 = err_planarity(X0, F);
err1 = err_planarity(X1, F);
figure(4);clf;
subplot(1,2,1); plot_building(X0, F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]); view([30,30])
subplot(1,2,2); plot_building(X1, F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]); view([30,30])


return



%% construct the facades of the nagoya palace
obj2 = obj; 
obj2.vid_outline = setdiff(obj2.vid_outline, [56:59, 77:80]);
obj2 = obj2.find_outline_contour();
M1 = construct_building_nagoya(X3, F, 150, {77:80, 56:59, obj2.outline_contour});


figure(6); clf;
plot_building(M1.verts, M1.faces);
%%
mesh_name = file_name;
M1.verts(:,1:2) = M1.verts(:,1:2) - mean(M1.verts(:,1:2));
M_body = M1;
M_roof = M1;

ind_roof = find(M1.face_labels == 1);
ind_body = setdiff(1:length(M1.face_labels), ind_roof);

M_body.faces(ind_roof) = [];
M_body.face_labels(ind_roof) = [];

M_roof.faces(ind_body) = [];
M_roof.face_labels(ind_body) = [];



my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_body);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M1);
matlab_process_roof_polyshape_windows(save_dir, mesh_name, save_dir);
