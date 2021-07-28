function [V_outline, A, adj] = read_dual_graph(dt_dir, file_name)
V_outline = dlmread([dt_dir, file_name, '.outline']);
adj = dlmread([dt_dir, file_name, '.adjacency']);
num = size(V_outline,1);
A = sparse(reshape(adj(:,1:2),[],1), reshape(adj(:,[2,1]),[],1), ones(size(adj,1)*2,1), num, num);
end