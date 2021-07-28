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
vid_z_height = [80,50,100,30];
% we add different randomness to the initial embeddings
randomness = [50,100,200,100];
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
    % add some randomness to the initial embedding
    X0(vid_z_var{i},3) = vid_z_height(i) + randomness(i)*(rand(length(vid_z_var{i}),1)-0.5);
end
% optimize the planarity
% do not add the variance constraint
X1 = construct_3D_roof_pavilion(obj.V, obj.F, vid_xy, vid_z, vid_z_var, lambda, X0, 0);
% add the variance constraint
X2 = construct_3D_roof_pavilion(obj.V, obj.F, vid_xy, vid_z, vid_z_var, lambda, X0, 1);

%% visualize the optimized rooftop
err0 = err_planarity(X0, F);
err1 = err_planarity(X1, F);
figure(2);clf;
subplot(1,3,1); plot_building(X0, F); title(['Initial Embedding: err = ', num2str(err0,'%.6f')]); view([0,30])
subplot(1,3,2); plot_building(X1, F); title(['wout variance penalty: err = ', num2str(err1, '%.6f')]); view([0,30])
subplot(1,3,3); plot_building(X2, F); title(['with variance penalty: err = ', num2str(err1, '%.6f')]); view([0,30])

