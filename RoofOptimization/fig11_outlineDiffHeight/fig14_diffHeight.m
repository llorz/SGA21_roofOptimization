clc; clear; clf;
addpath(genpath('../utils/'))
all_imgs = dir('data/*.jpg');
ifile = 4; % set from 1 to 16
file_name = all_imgs(ifile).name;
I = imread(['data/',file_name]);

dt_dir = 'data/';
save_dir = ['./results/',file_name(1:end-4),'/'];
if ~isfolder(save_dir), mkdir(save_dir); end
%% set parameters
para.eps_mergethres = 1e-2;
para.eps_ortho = 1e-2;
para.eps_converge = 1e-6;
para.eps_degree = 2;
para.ifSaveFig = false;
para.ifShowFig = true;
para.eps_merge = 1e-3;
para.roof_height = 50;
para.body_height = 100;

%% read and construct the roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);
% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf;
plot(obj); title('input roof graph')
%% light pre-processing
obj = RoofGraph(V, F);
[obj,R] = axis_align_roof_graph(obj);
obj = reindex_roofgraph(obj);
[obj, edges_group, fixed_degrees] = regularize_outline_edges(obj, para);
figure(2); clf;
plot(obj); title('pre-processing')
%% set up the variables for optimization
% we allow some outline vertices to be modified during the optimization
if ifile == 1
    ovid_z = 6:10;
    ovid_x = 10;
    ovid_y = [];
    var_z = 7:10;
    para.lambda = 1e-5;
elseif ifile == 2
    ovid_z = 9:11;
    ovid_y = obj.vid_outline;
    ovid_x =obj.vid_outline;
    var_z = {[9,10,11], [12,13,14]};
    para.lambda = 1e-2;
elseif ifile == 3
    ovid_z = 15:18;
    ovid_x =17;
    ovid_y = 16;
    var_z = {[17,18],[15,16]};
    para.lambda = 1e-5;
elseif ifile == 4
    ovid_z = [1;2;3;4;5;15];
    ovid_x = 4;
    ovid_y = [1,2];
    var_z = {[1,2,3,15], [4,5]};
    para.lambda = 1e-3;
end
vid_x = [obj.vid_roof; ovid_x(:)];
vid_y = [obj.vid_roof; ovid_y(:)];
vid_z = [obj.vid_roof; ovid_z(:)];
%%
X0 = [obj.V, zeros(obj.nv,1)];
X0(obj.vid_roof, 3) = para.roof_height;
X1  = construct_3D_roof_local(X0, obj.F, vid_x, vid_y, vid_z, var_z, para.lambda, X0);
%% visualize the optimized rooftop
err0 = err_planarity(X0, obj.F);
err1 = err_planarity(X1, obj.F);
figure(3);clf;
subplot(1,2,1); plot_building(X0, obj.F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]);
subplot(1,2,2); plot_building(X1, obj.F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]);

%%
vid_plot = find(X1(:,3) < -eps);
M1 = construct_building(X1, obj.F, para.body_height);
figure(4); clf;
plot_building(M1.verts, M1.faces); hold on;
scatter3(M1.verts(vid_plot,1), M1.verts(vid_plot,2), M1.verts(vid_plot,3),100,'filled','red');
title('Red: outline vtx with different height')
%% write the shape
% I save three shapes: building/roof/body for rendering
mesh_name = file_name(1:end-4);
M1 = construct_building(X1, obj.F, para.body_height);
M1.verts(:,1:2) = M1.verts(:,1:2) - mean(M1.verts(:,1:2));
% we separate the roof and the body
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
