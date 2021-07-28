clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')

lambda = 0.001;
roof_height = 25;
body_height = 50;

s_name = 'tulou';

dt_dir = ['./data/',s_name,'/'];
save_dir = ['./results/',s_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end

sid = 2; % can be set to 0,1,2
file_name = [s_name, num2str(sid,'%02d')];
%% read and construct the roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);
% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf;
plot(obj);
%% optimize the rooftop
[~,id] = max(arrayfun(@(vid) length(obj.find_rvtx_neighboring_redges(vid)), obj.vid_roof));
fixed_vid = obj.vid_roof(id);
% vid_xy: we allow these vertices to change their xy coordinates
vid_xy = 1:obj.nv;
% vid_z: we allow these vertices to change their z coordinate
vid_z = obj.vid_roof;
% set the initial embedding X0
X0 = [obj.V, zeros(obj.nv,1)];
% the z-axis value of the roof vertices are set to default height
X0(obj.vid_roof, 3) = roof_height;
% optimize the planarity
X1 = construct_3D_roof_tulou(obj.V, obj.F, vid_xy, vid_z, lambda, X0);
%% visualize the optimized rooftop
err0 = err_planarity(X0, F);
err1 = err_planarity(X1, F);
figure(2);clf;
subplot(1,2,1); plot_building(X0, F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]);
subplot(1,2,2); plot_building(X1, F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]);


return


%% consturct the facades of the buildings
% here I manually specify the vtxID of the interior (oc1) and exterior
% (oc2) of the ouline contour, which can be detected automatically. 
% But Jing is too lazy (stupid) to work it out
if sid == 0
    oc2 = [5,6,7,8];
    oc1 = [9,10,11,12];
elseif sid == 1
    oc1 = [5,6,9,12,15,18,21,22,42,27,32,35,36,41];
    oc2 = [38,33,30,29,25,24,20,17,14,10,7,2,1,39];
elseif sid == 2
    oc1 = [31,36,39,40,5,6,9,12,15,18,21,24,27,30];
    oc2 = [33,34,38,42,1,2,8,10,13,16,19,22,25,28];
end

M1 = construct_building_tulou(X1, F, body_height, {oc1, oc2});

figure(3);clf;
plot_building(M1.verts, M1.faces)

%% write the shape
% I save three shapes: building/roof/body for rendering
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

% shrink the facades inward a bit to make it look better :)
vid1 = unique(cell2mat(M1.faces(M1.face_labels == 3)));
vid2 = unique(cell2mat(M1.faces(M1.face_labels == 4)));
M_body.verts(vid1,1:2) = M_body.verts(vid1,1:2)*1.05;
M_body.verts(vid2,1:2) = M_body.verts(vid2,1:2)*0.95;

% save the polyshape and obj (use blender)
my_write_polygon_shapes(save_dir,[ mesh_name, '_body'], M_body);
my_write_polygon_shapes(save_dir,[ mesh_name, '_roof'], M_roof);
my_write_polygon_shapes(save_dir,mesh_name, M1);
matlab_process_roof_polyshape_windows(save_dir, mesh_name, save_dir);
