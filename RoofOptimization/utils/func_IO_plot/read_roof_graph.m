function [V, F] = read_roof_graph(dt_dir, file_name)
V = dlmread([dt_dir, file_name, '.verts']);
% face
F_tmp = dlmread([dt_dir, file_name, '.faces']);
F = cell(size(F_tmp,1),1);
for i = 1:size(F_tmp,1)
    f = F_tmp(i,:);
    ind = find(f == f(1));
    f(ind(2):end) = [];
    F{i} = f + 1;
end
end