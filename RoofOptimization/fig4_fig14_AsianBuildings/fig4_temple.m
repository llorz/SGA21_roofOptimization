clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')

lambda = 0.001;
roof_height = 200;
body_height = 150;

file_name = 'temple';

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
%% User input
% we can specify that some vertices should be in a similar height
% this is done by penalizing the variance of the vertex heights
vid_z_var = { [11:14];...
    [7:10];...
    [3:6]};

% the rough height for each group of vertices
vid_z_height = [40, 80, 110];

% modify the roof graph to enforce the vertical facades
% this can also be enforced during optimization
vid_xy_var = [9,11; 10,12; 8,14; 7,13];
V(vid_xy_var(:,1),:) = V(vid_xy_var(:,2),:);
%%  optimize the rooftop
% update the roofgraph
obj = RoofGraph(V, F);
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
subplot(1,2,1); plot_building(X0, F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]); view([30,45])
subplot(1,2,2); plot_building(X1, F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]); view([30,45])


M1 = construct_building(X1, F, body_height);
figure(3);clf;
plot_building(M1.verts, M1.faces); hold on; view([30,5])


return


%% add texture from the template sketch
I = imread([dt_dir, 'temple.jpg']);
tmp = dlmread([dt_dir, '/roof_uv.verts']);
figure(4); clf; imshow(I); hold on;
scatter(tmp(:,1), tmp(:,2), 'filled'); title('texture coord')

vid = [1,5,8,14,16,20,2,6,7,13,17,21,3,10,12,18,22];
S_vt = zeros(size(M1.verts,1),2);
S_vt(vid, 2) = 1 - tmp(:,2)/size(I,1);
S_vt(vid,1) = tmp(:,1)/size(I,2);

%%
M1.verts(:,1:2) = M1.verts(:,1:2) - mean(M1.verts(:,1:2));
mesh_name = file_name;
imwrite(I,[save_dir, mesh_name, '.jpg'],'jpeg');
dlmwrite([save_dir ,mesh_name, '_texture_coord.txt'], S_vt);

mesh_name = file_name;
M_body = M1;
M_roof = M1;

ind_roof = find(M1.face_labels == 1);
ind_body = setdiff(1:length(M1.face_labels), ind_roof);

M_body.faces(ind_roof) = [];
M_body.face_labels(ind_roof) = [];

M_roof.faces(ind_body) = [];
M_roof.face_labels(ind_body) = [];

M_body.verts(:,1:2) = M_body.verts(:,1:2)*0.95;


my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_body);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M1);
matlab_process_roof_polyshape_windows(save_dir, mesh_name, save_dir);