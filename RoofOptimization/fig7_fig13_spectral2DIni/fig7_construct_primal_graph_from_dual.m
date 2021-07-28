clc; clear; clf;
addpath(genpath('../utils/'))


file_name = 'test';
dt_dir = 'data/';
save_dir = ['./results/',file_name,'/'];
if ~isfolder(save_dir), mkdir(save_dir); end
%% read the primal roof graph
% vertex 2D positions
[V, F] = read_roof_graph(dt_dir, file_name);
% construct roof graph
obj = RoofGraph(V, F);
figure(1); clf;
plot(obj); title('primal roof graph');
%% read the dual graph
[V_outline, A] = read_dual_graph(dt_dir, file_name);
figure(2); clf;
plot_dual_graph(V_outline, A); title('dual roof graph');
%% construct the primal graph from the dual
% eps_ortho = 1e-6;
[V1, F1, roofrays] = compute_roofgraph_from_dualgraph(V_outline, A);
obj2 = RoofGraph(V1, F1);
figure(3); clf;
plot(obj2); title('reconstruct primal roof graph from the dual');
%% optimize for roof planarity
lambda = 0; 
roof_height = 50;
[X1, X0] = construct_3D_roof_from_roof_graph(obj2.V(obj2.vid_outline,:), obj2.F, obj2.V, roof_height, lambda);
%% visualize the optimized rooftop
err0 = err_planarity(X0, obj2.F);
err1 = err_planarity(X1, obj2.F);
figure(4);clf;
subplot(1,2,1); plot_building(X0, obj2.F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]); view([220,45])
subplot(1,2,2); plot_building(X1, obj2.F); title(['Optimized Embedding: err = ', num2str(err1, '%.6f')]); view([220,45])