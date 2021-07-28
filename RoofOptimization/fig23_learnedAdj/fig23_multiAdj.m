clc; clear;clf;
addpath(genpath('../utils/'))
addpath('func_local/')
roof_height = 3;

file_name = '0012_00';

dt_dir = ['./data/',file_name,'/'];
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end
%% load the predicted face adjacencies
[V_outline, A] = read_dual_graph(dt_dir, file_name);
figure(1); clf;
plot_dual_graph(V_outline, A); title('predicted face adjacency');
%% extract multiple valid dual graphs from the learned face adjacencies
all_A = extract_multiAdj_from_learned_adj(V_outline, A);
%% construct roofs from extracted valid dual graph
V = V_outline;
para.eps_ortho = 1e-3;
para.minEdgeLen = 0.1;
para.lambda_ini = 0;
para.w_angle = 1e-3;
para.w_bisector = 1;
para.w_equal = 1;

test_aids = [1,3,4,9,10,18,20,38];

rng(2)


for ii = 1:length(test_aids)
    aid = test_aids(ii);
    A = all_A{aid};
    [V_roof, F_roof, roofrays] = compute_roofgraph_from_dualgraph(V_outline, A);
    obj = RoofGraph(V_roof, F_roof);
    obj1 = optimize_2D_feasible_roofgraph_constrainted(obj, para);
    
    % some editings to make the roof look nicer
    % mainly moving some vertex around
    if ismember(aid, [1,18,3,9,38,10,4])
        if aid == 1, vid = 17; mov_pos = [-2,0]; end
        if aid == 3, vid = 16; mov_pos = [-2,0]; end
        if aid == 4, vid = 16; mov_pos = [1,0]; end
        if aid == 9,  vid = 13; mov_pos = [-3.5,0]; end
        if aid == 10, vid = 20; mov_pos = [-3,0]; end
        if aid == 18, vid = 17; mov_pos = [2,2]; end
        if aid == 38, vid = [15,16]; mov_pos = [-2,5; -2,0]; end
        obj2 = obj1;
        obj2.V(vid,:) = obj2.V(vid,:) + mov_pos;
        obj2 = optimize_2D_feasible_roofgraph_close2ini(obj2, para);
    else
        obj2 = obj1;
    end
    
    obj = obj2;
    [~, area] = convhull(V);
    roof_height = sqrt(area)/8;
    
    X1 = construct_3D_roof_from_straight_skeleton(obj.V, obj.F, obj.vid_roof, roof_height);
    
    body_height = 2*roof_height;
    M2 = construct_building(X1, obj.F, body_height);
    M2.verts(:,1:2) = M2.verts(:,1:2) - mean(M2.verts(:,1:2));
    
    % plot the extracted adjacency
    figure(2); subplot(2,4,ii); cla;
    plot_dual_graph(V_outline, A); axis square;
    % plot the reconstructed roof
    figure(3);  subplot(2,4,ii); cla;
    plot_building(M2.verts, M2.faces);
    
    % save the constructed shapes
    my_write_polygon_shapes(save_dir, [file_name,'_',num2str(ii)], M2);
    convert_polyshape_to_obj_wout_texture(M2, [file_name,'_', num2str(ii)], save_dir);
    
end