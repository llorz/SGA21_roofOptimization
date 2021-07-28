clc; clear; clf;
addpath(genpath('../utils/'))
all_imgs = dir('data/*.jpg');
ifile = 15; % set from 1 to 16
file_name = all_imgs(ifile).name(1:end-4);
I = imread(['data/',file_name, '.jpg']);

dt_dir = 'data/labels/';
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end

%% set parameters
para.eps_mergethres = 1e-2;
para.eps_ortho = 1e-1;
para.eps_converge = 1e-6;
para.ifSaveFig = false;
para.ifShowFig = true;
para.eps_merge = 1e-3;
para.roof_height = 50;
para.body_height = 100;
para.lambda = 1e-1;
%% read and construct the roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);
% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf;
plot(obj); title('input roof graph')
%% light pre-processing
[obj,R] = axis_align_roof_graph(obj);
obj = regularize_outline_edges(obj);
% obj = reindex_roofgraph(obj);
obj.V = obj.V*R';
figure(2); clf;
plot(obj); title('pre-processing')
%% construct a 3D planar roof from the graph
% we fix the height of one roof vertex to avoid trivial solution
[~,id] = max(arrayfun(@(vid) length(obj.find_rvtx_neighboring_redges(vid)), obj.vid_roof));
if ifile == 1
    fixed_vid = [51,50]; % to make it more symmetric
else
    fixed_vid = obj.vid_roof(id);
end
% vid_xy: we allow these vertices to change their xy coordinates
vid_xy = 1:obj.nv;
% vid_z: we allow these vertices to change their z coordinate
vid_z = setdiff(obj.vid_roof, fixed_vid);
% set the initial embedding X0
X0 = [obj.V, zeros(obj.nv,1)];
% the z-axis value of the roof vertices are set to default height
X0(obj.vid_roof, 3) = para.roof_height;
% optimize the planarity
X1 = reconstruct_3D_roof(obj.V, obj.F, vid_xy, vid_z, para.lambda, X0);
%% visualize the optimized rooftop
err0 = err_planarity(X0, obj.F);
err1 = err_planarity(X1, obj.F);
figure(3);clf;
subplot(1,2,1); plot_building(X0, obj.F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]);
subplot(1,2,2); plot_building(X1, obj.F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]);
%%
I2 = flip(I ,2);           %# horizontal flip
mycolor = lines(100);
figure(4); clf;
subplot(1,2,1); imshow(I2); title('Input Image')
Y = X1;
F = obj.F;

subplot(1,2,2); cla;
imshow(I2); hold on;
scatter(Y(:,1), Y(:,2), 100, 'filled'); hold on;
for fid = 1:length(F)
    tmp = Y(F{fid},:);
    fill(tmp(:,1), tmp(:,2),mycolor(fid,:),'FaceAlpha',0.5);
end
title('Overlayed with optimized roof embedding')
%% write the shape
% I save three shapes: building/roof/body for rendering
mesh_name = file_name;
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

imwrite(I2,[save_dir, mesh_name, '.jpg'],'jpeg');
num = size(X1,1);
S_vt = zeros(num,2);
S_vt(:,2) = 1-X1(:,2)/size(I,1);
S_vt(:,1) = X1(:,1)/size(I,2);
dlmwrite([save_dir ,mesh_name, '_texture_coord.txt'], S_vt);

my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_body);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M1);
matlab_process_roof_polyshape_windows(save_dir, mesh_name, save_dir);
