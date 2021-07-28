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
obj = reindex_roofgraph(obj);
figure(1); clf;
plot(obj); title('primal roof graph');
%% compute the spectral embedding
V_outline = obj.V(obj.vid_outline,:);
% initailize the 2D embedding where all the roof vtx are set to the origin
X0 = [V_outline; zeros(length(obj.vid_roof),2)];
[X1, history] = get_initial_graph_layout_by_Laplacian_iter(V_outline, obj.F, X0);
%% visualization
for iter = 1:size(history.x,2)
    x = history.x(:, iter);
    Y = [V_outline; reshape(x,[],2)];
    obj2 = RoofGraph(Y, obj.F);
    figure(2); plot(obj2); title(['iter: ',num2str(iter, '%02d')]);
    pause(0.4);
end