clc; clear; clf;
addpath(genpath('utils/'));
para.eps_ortho = 1e-3;
para.lambda_minEdgeLen = 0;
para.minEdgeLen = 0.5;
para.lambda_ini = 1e-6;
%%
dt_dir = './data_editting/';

mesh_name = 'BJ39_500_099050_0031';
[V_cgal, F_cgal] = read_straight_skeleton([dt_dir, mesh_name, '.faces']);
M0 = my_read_polygon_shapes(dt_dir, mesh_name);
figure(10); plot_building(M0.verts, M0.faces);
%%
% obj_target = RoofGraph(M0.verts(:,1:2), M0.faces(M0.face_labels==1));
% figure(11); plot(obj_target);
obj = RoofGraph(V_cgal, F_cgal);
obj = reindex_roofgraph(obj);
[obj,R] = axis_align_roof_graph(obj);

obj = regularize_outline_edges(obj);
obj.V = obj.V*R';
I = imread([dt_dir, mesh_name, '.jpg']);
figure(1); clf; 
imshow(I);
hold on;
plot(obj)
%%
% regularize the outline a bit
% trans = mean(obj_target.V(obj_target.outline_contour,:)) - mean(obj.V(obj.outline_contour,:));
% obj.V = obj.V + trans;
% obj.V(obj.outline_contour, :) = obj_target.V(obj_target.outline_contour,:);
% obj = optimize_2D_feasible_roofgraph_close2ini(obj, para);
% obj1 = obj;
figure(1); clf;
plot(obj)
%%  step 01: remove edge
obj_tmp = obj;
rm_eid = 43;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);
rm_eid = 47;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);

obj2 = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
figure(3); clf;
plot(obj2)
%% step02: merge two faces 4, 8
obj_tmp = obj2;
rm_eid = 58;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);

rm_eid = 56;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);

figure(3); clf; 
plot(obj_tmp)


ref_fid1 = 8;ref_fid2 = 4;
obj_tmp = merge_two_faces(obj_tmp, ref_fid1, ref_fid2);


rm_eid = 53;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);

vid = 36; mov_pos = [0,-10];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;
obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);

obj3 = obj_tmp;
figure(3); clf;
plot(obj3)
%% step 03: fix adjacency
obj_tmp = obj3;
rm_eid = 48;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);
rm_eid = 48;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);
obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
obj4 = obj_tmp;
figure(3); clf;
plot(obj4)
%% step 04: fix
para.lambda_ini = 0;
% obj_tmp = obj4;
% obj_tmp.F{11} = [9,28,29,10];
% obj_tmp.F{12} = [8,28,9];
% obj_tmp = RoofGraph(obj_tmp.V, obj_tmp.F);
% 
% ref_fid1 = 11; ref_fid2 = 13;
% obj_tmp = force_two_face_adjacent(obj_tmp, ref_fid1, ref_fid2);
obj_tmp = obj4; ref_fid1 = 12; ref_fid2 = 14;
obj_tmp = force_two_face_adjacent(obj_tmp, ref_fid1, ref_fid2);
obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
% obj5 = obj_tmp
vid = 28; mov_pos = [-30,0];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;
obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
obj5 = obj_tmp;
% obj5.F{10}(2) = []; % fix here
figure(5); clf;
plot(obj5)
%% step 05: split face and merge

obj_tmp = obj5;
% split face at an edge
% obj_tmp.F(10) = [];
% obj_tmp.F{end+1} = [10,30,11]';
% obj_tmp.F{end+1} = [11,30,29]';
fid = 11; vid1 = 11; vid2 = 30;
obj_tmp = split_face_at_two_vtx(obj_tmp, fid, vid1, vid2);
obj_tmp = RoofGraph(obj_tmp.V, obj_tmp.F);

obj_tmp = merge_two_faces(obj_tmp, 13, 20);
rm_eid = 52;
obj_tmp = remove_ridge_edge(obj_tmp, rm_eid);
obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);

vid = 29; mov_pos = [0,40];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;
vid = 30; mov_pos = [20,0];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;

obj_tmp = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
obj6 = obj_tmp;
figure(3);clf;
plot(obj6)
%% step 06: move edge & vertex
eid = 46;
obj_tmp = obj6;
obj_tmp.V(obj_tmp.E(eid,:),:) = obj_tmp.V(obj_tmp.E(eid,:),:) + [-50, 0];
vid = 31; mov_pos = [0,-53];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;
vid = 32; mov_pos = [58,0];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;

vid = 28; mov_pos = [-35,0];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;
vid = 30; mov_pos = [40,0];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;

vid = 22; mov_pos = [15,15];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;

vid = 26; mov_pos = [2,5];
obj_tmp.V(vid,:) = obj_tmp.V(vid,:) + mov_pos;


obj7 = optimize_2D_feasible_roofgraph_close2ini(obj_tmp, para);
figure(1); clf;
plot(obj7)
%% plot the results
% save_dir = ['res_wss_edit/']; mkdir(save_dir);
obj = obj1;
obj.V = obj.V*[0,1;-1,0];
obj.V = obj.V/500*8;
figure(1);  clf;
plot(obj); axis equal;

%% ours
all_objs = {obj1, obj2, obj3, obj4, obj5, obj6, obj7};
all_X1 = cell(length(all_objs),1);
all_M = cell(length(all_objs),1);
roof_height = 50;
body_height = 2*roof_height;

for i = 1:length(all_objs)
    obj = all_objs{i};
    X1 = construct_3D_roof_from_straight_skeleton(obj.V, obj.F, obj.vid_roof, roof_height);
    M = construct_building(X1, obj.F, body_height);
    
    all_X1{i} = X1;
    all_M{i} = M;
end

figure(7); clf;
for i = 1:length(all_M)
    subplot(1, length(all_M), i);
    M = all_M{i};
    plot_building(M.verts, M.faces);
end

%% wss
all_X1_wss = cell(length(all_objs),1);
all_M_wss = cell(length(all_objs),1);
ss_dt_dir = '/Users/renj/Downloads/BJ39_500_099050_0031_result_202101191444/';
[V_wss, F_wss] = read_weighted_straight_skeleton([ss_dt_dir, mesh_name,'_',num2str(7,'%02d'),'.faces']);
obj = RoofGraph(V_wss(:,1:2), F_wss);
V_outline = obj.V(obj.outline_contour,:);

%%
for k = 1:7
    [V_wss, F_wss] = read_weighted_straight_skeleton([ss_dt_dir, mesh_name,'_',num2str(k,'%02d'),'.faces']);
    obj = RoofGraph(V_wss(:,1:2), F_wss);
    obj.outline_contour = knnsearch(obj.V, V_outline);
    X1 = construct_3D_roof_from_straight_skeleton(obj.V, obj.F, obj.vid_roof, roof_height);
    %     M = construct_building(X1, obj.F, body_height);
    M = construct_building_wss(X1, obj.F, body_height, obj.outline_contour);
    all_X1_wss{k} = X1;
    all_M_wss{k} = M;
end
%%
figure(8); clf;
for i = 1:length(all_M)
    subplot(1, length(all_M), i);
    M = all_M_wss{i};
    plot_building(M.verts, M.faces);
end
%% save_results
save_dir = ['data/res_wss_edit/']; mkdir(save_dir);
center = mean(all_M{i}.verts);
for i = 5:7
    M = all_M{i};
    M.verts = M.verts/200;
    M.verts(:,1:2) = M.verts(:,1:2) - center(1:2);
    convert_polyshape_to_obj_wout_texture(M, [num2str(i),'_ours'], save_dir);
% %     M = all_M_wss{i};
%     M.verts = M.verts/200;
%     M.verts(:,1:2) = M.verts(:,1:2) - mean(M.verts(:,1:2));
%     
%     convert_polyshape_to_obj_wout_texture(M, [num2str(i),'_wss'], save_dir);
end
