clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')
roof_height = 3;

file_name = '2527_00';

dt_dir = ['./data/',file_name,'/'];
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end
%% results of straight skeleton method
% Reference: https://doc.cgal.org/latest/Straight_skeleton_2/index.html
% which takes an roof outline (a sequence of 2D positions in
% counter-clockwise order) as input, and output a feasible 2D embedding of
% a roof
[V_cgal, F_cgal] = read_straight_skeleton([dt_dir, file_name, '.faces']);
obj_cgal = RoofGraph(V_cgal, F_cgal);
obj_cgal = reindex_roofgraph(obj_cgal);
figure(1); clf; plot(obj_cgal); title('Valid 2D embedding from straight skeleton')
% construct a 3D embedding from the valid 2D embedding by solving for the
% z-axis values of each roof vertex (see last paragraph of Sec.3.1. for a detailed discussion)
X1 = construct_3D_roof_from_straight_skeleton(obj_cgal.V, obj_cgal.F, obj_cgal.vid_roof, roof_height);
figure(2); clf;
plot_building(X1, obj_cgal.F); title('Valid 3D embedding from straight skeleton')
%% fix the dual graph of the roof
% check Figure 1, to fix the roof graph
% we first remove some wrong adjacencies
% e.g., the face(19,20) should not be adjacent to face(4,5)
% and face(15,16) should not be adjacent to face(8,9)
% here face(i,j) means the face that contains the outline edge(i,j)
rm_adj = [4,19;...
    15,8];
% we furthre want to enforce that the edges (12,13), (16,17), and (20,1)
% should belong to the same face
merge_eid = [12,16,20]; 

% here is how we fix the dual graph as illustrated in Fig. 15
A = extract_adjacency(obj_cgal);
A_new = A;
for i = 1:size(rm_adj, 1)
    A_new(rm_adj(i,1), rm_adj(i,2)) = 0;
    A_new(rm_adj(i,2), rm_adj(i,1)) = 0;   
end

A_new(merge_eid(1), :) = sum(A(merge_eid, :)) > 0;
A_new(:, merge_eid(1)) = sum(A(merge_eid, :)) > 0;
A_new(merge_eid(2:end),:) = 0;
A_new(:, merge_eid(2:end)) = 0;
%% Force the edges in merge_eids in the same line
% find the outline vtx on the edges in merge_eid
vtxRef = repmat(1:length(obj_cgal.vid_outline),1,2);
vids = vtxRef([merge_eid, merge_eid+1]);
% todo: this need to be done in a clean way
% i.e,. just make sure these four points are in the same line
[~, axis_id] = min(var(obj_cgal.V(vids,:)));
obj_cgal.V(vids, axis_id) = obj_cgal.V(vids(1), axis_id);

%% ours: first construct the roof graph from the updated dual graph
V_outline = obj_cgal.V(obj_cgal.vid_outline,:);
[V1, F1, roofrays] = compute_roofgraph_from_dualgraph(V_outline, A_new);
obj2 = RoofGraph(V1, F1);
figure(3); plot(obj2); title('Updated Roof Graph')

% optimize for a valid 2D embedding
para.eps_ortho = 1e-3;
para.minEdgeLen = 1e-3;
obj1 = optimize_2D_feasible_roofgraph(obj2, para);
obj2 = heuristic_move_parallel_ridge_to_medialAxis(obj1);
obj3 = heuristic_roofedge_as_angle_bisector(obj2, para);
obj_ours = optimize_2D_feasible_roofgraph(obj3, para);
figure(4); plot(obj_ours); title('Our valid 2D embedding')
% optimize for a valid 3D embedding from the valid 2D embedding
% we can also optimize for a valid 3D embedding directly
% here we separate it into two steps just to make it directly comparable
% with the straight skeleton method
X2 = construct_3D_roof_from_straight_skeleton(obj_ours.V, obj_ours.F, obj_ours.vid_roof, roof_height);
figure(5); clf;
subplot(1,2,1);
plot_building(X1, obj_cgal.F); title('Valid 3D embedding from straight skeleton')
subplot(1,2,2);
plot_building(X2, obj_ours.F); title('Valid 3D embedding from straight skeleton')


return



%% save the constructed buildings
body_height = 2*roof_height;
M1 = construct_building(X1, obj_cgal.F, body_height);
M2 = construct_building(X2, obj_ours.F, body_height);

figure(6); clf;
subplot(1,2,1); plot_building(M1.verts, M1.faces); title('Straight Skeleton')
subplot(1,2,2); plot_building(M2.verts, M2.faces); title('Ours')

center = [mean(M1.verts(:,1:2)),0];
M1.verts = M1.verts - center;
M2.verts = M2.verts - center;
my_write_polygon_shapes(save_dir, [file_name,'_cgal'], M1);
convert_polyshape_to_obj_wout_texture(M1, [file_name,'_cgal'], save_dir);

my_write_polygon_shapes(save_dir, [file_name,'_ours'], M2);
convert_polyshape_to_obj_wout_texture(M2, [file_name,'_ours'], save_dir);
