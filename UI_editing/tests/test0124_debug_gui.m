clc; clf; clear;
addpath(genpath('./utils/'));
%%
para.eps_mergethres = 1e-2;
para.eps_ortho = 1e-1;
para.eps_converge = 1e-6;
para.ifSaveFig = false;
para.ifShowFig = true;
para.eps_merge = 1e-3;
para.roof_height = 50;
para.body_height = 100;
%%
dt_dir = './data/';
all_files = dir([dt_dir,'*.jpg']);
ifile = 11;
file_name = all_files(ifile).name(1:end-4);
% read the verts and faces
V = dlmread([dt_dir,'labels/', file_name, '.verts']);
F_tmp = dlmread([dt_dir,'labels/', file_name, '.faces']);
F = cell(size(F_tmp,1),1);
for i = 1:size(F_tmp,1)
    f = F_tmp(i,:);
    ind = find(f == f(1));
    f(ind(2):end) = [];
    F{i} = f + 1;
end
%%
obj = RoofGraph(V, F);
[obj,R] = axis_align_roof_graph(obj);
obj = regularize_outline_edges(obj);
obj.V = obj.V*R';
obj = reindex_roofgraph(obj);
figure(3); clf;
imshow(I); hold on;
plot(obj);
%%

[~,id] = max(arrayfun(@(vid) length(obj.find_rvtx_neighboring_redges(vid)), obj.vid_roof));
fixed_vid = obj.vid_roof(id);

lambda = 0.1;
V_outline = obj.V(obj.outline_contour,:);
a = tic;
[X1] = construct_3D_roof_from_roof_graph(V_outline,obj.F, obj.V, 50, lambda, fixed_vid);
t = toc(a);
%%
obj = RoofGraph(V, F);
obj1 = regularize_outline_edges(obj);
obj2 = optimize_2D_feasible_roofgraph(obj1, para);

figure(1); clf; plot(obj)
figure(2); clf; plot(obj1)
figure(3); clf; plot(obj2)