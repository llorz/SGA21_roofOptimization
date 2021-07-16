function [V_roof, F_roof, roofrays] = compute_roofgraph_from_dualgraph_v2(V_outline, E_dual, merge_eids, para)
if nargin < 3, para = struct(); end
if ~isfield(para,'eps_ortho'), para.eps_ortho = 1e-6; end
if ~isfield(para,'eps_nndist'), para.eps_nndist = 1e-6; end


%------------------------------------------------------
% detect the edges in the dual graph (from adjacency)
%------------------------------------------------------
% for each i, say  e1 = E(i,1); e2 = E(i,2);
% we then know that the face with outline_edges(e1,:) should be adjacent
% with the face with outline_edges(e2,:)
roofrays = [];
for i = 1:size(E_dual,1)
    eid1 = E_dual(i,1); eid2 = E_dual(i,2);
    ray = construct_roofrays_from_outline_v2(V_outline, eid1, eid2, merge_eids, para.eps_ortho);
    ray.count = ray.edgetype;
    roofrays = [roofrays, ray];
end

[V_ini, E_roof, roofrays] = construct_roofgraph_from_roofrays(roofrays, V_outline);
F_roof = extract_faces_from_roofgraph(roofrays, E_roof, E_dual);
V_roof = roofgraph_Laplacian_embedding(V_ini, E_roof, V_outline);
end



