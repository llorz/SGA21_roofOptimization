clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')

lambda = 0.001;
roof_height = 200;
body_height = 50;

file_name = 'pavilion';

dt_dir = ['./data/',file_name,'/'];
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end


%% read and construct the roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);
% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf;
plot(obj);
%% user input
% we can specify that some vertices should be in a similar height
% this is done by penalizing the variance of the vertex heights
vid_z_var = { [2,3,4,5,6,7];...
    [8,9,10,11,12,13];...
    [14,15,16,17,18,19];...
    [20,21,22,23,24,25,26,27,28,29,30,31]};

% the rough height for each group of vertices
vid_z_height = [100,50,100,30];

%%  optimize the rooftop
% vid_xy: we allow these vertices to change their xy coordinates
vid_xy = 1:obj.nv;
% vid_z: we allow these vertices to change their z coordinate
vid_z = obj.vid_roof;
% we also allow some of the outline vertices to have nonzero height
vid_z = [vid_z(:); unique(reshape(cell2mat(vid_z_var'),[],1))];
vid_z = unique(vid_z);

% set the initial embedding X0
X0 = [obj.V, zeros(obj.nv,1)];
X0(vid_z, 3) = roof_height;
for i = 1:length(vid_z_var)
X0(vid_z_var{i},3) = vid_z_height(i);
end
% optimize the planarity
X1 = construct_3D_roof_pavilion(obj.V, obj.F, vid_xy, vid_z, vid_z_var, lambda, X0);
%% visualize the optimized rooftop
err0 = err_planarity(X0, F);
err1 = err_planarity(X1, F);
figure(2);clf;
subplot(1,2,1); plot_building(X0, F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]); view([0,30])
subplot(1,2,2); plot_building(X1, F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]); view([0,30])


return


%%  consturct the base of the pavilion
% ah this looks stupid again :(
% the base is constructed from the rooftop directly
% the pillars are added as cylinders during rendering 
X_base = [X1([8,9,13,12,11,10],1:2),-200*ones(6,1)];
F_base = {1:6};
M_base = construct_building(X_base, F_base, 100);
M_base.verts(:,3) = M_base.verts(:,3) - 400;

center = mean(M_base.verts(:,1:2));
M_base.verts(:,1:2) = (M_base.verts(:,1:2) -center) *1.1 + center;

figure(3); clf;
plot_building(X1, F); hold on;
plot_building(M_base.verts, M_base.faces); view([0,30])
%%
mesh_name = file_name;
center = [mean(X1(:,1:2)), 0];
M_roof.verts = X1 - center; M_roof.faces = F; M_roof.face_labels = ones(size(F,1),1);
M_base.verts = M_base.verts - center;
my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_base);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M_roof);
matlab_process_roof_polyshape_windows(save_dir, mesh_name, save_dir);

