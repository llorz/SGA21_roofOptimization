function obj_new = reindex_roofgraph(obj)
% make the outline in clockwise order
outline_contour = obj.outline_contour;
V = obj.V(outline_contour,:);
X = reindex_outline(V);
if isequal(X, V)
else
    outline_contour = outline_contour(end:-1:1);
end

% re-index the vertex/edges, to make the outline vertices in a clockwise order
index_refTable = zeros(obj.nv,2);
index_refTable(:,1) = 1:obj.nv;
index_refTable(outline_contour,2) = 1:length(outline_contour);
index_refTable(setdiff(1:obj.nv, outline_contour), 2) = ...
    (length(outline_contour) + 1):obj.nv;

[~, ic] = sort(index_refTable(:,2));
X_new = obj.V(ic,:);
F_new = cell(size(obj.F));
for i = 1:obj.nf
    F_new{i} = index_refTable(obj.F{i},2);
end

num = length(outline_contour);
outline_edges = [(1:num)', [2:num, 1]'];
obj_new = obj.update(X_new, F_new, outline_edges);
end