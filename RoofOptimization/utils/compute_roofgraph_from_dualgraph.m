function [V_roof, F_roof, roofrays] = compute_roofgraph_from_dualgraph(V_outline, A, para)
if nargin < 3, para = struct(); end
if ~isfield(para,'eps_ortho'), para.eps_ortho = 1e-6; end
if ~isfield(para,'eps_nndist'), para.eps_nndist = 1e-6; end


[i,j] = ind2sub(size(A),find(A));
% the adjacency information
E = [i,j];
E = [min(E,[],2), max(E,[],2)];
E = unique(E,'rows');

E_dual  = E;
outline_edges = [V_outline, V_outline([2:size(V_outline,1),1],:)];
%------------------------------------------------------
% detect the edges in the dual graph (from adjacency)
%------------------------------------------------------
% for each i, say  e1 = E(i,1); e2 = E(i,2);
% we then know that the face with outline_edges(e1,:) should be adjacent
% with the face with outline_edges(e2,:)
roofrays = [];
for i = 1:size(E_dual,1)
    eid1 = E_dual(i,1); eid2 = E_dual(i,2);
    ray = construct_roofrays_from_outline(outline_edges, eid1, eid2, V_outline, ...
        para.eps_ortho, para.eps_nndist);
    ray.count = ray.edgetype;
    roofrays = [roofrays, ray];
end

[V_ini, E_roof, roofrays] = construct_roofgraph_from_roofrays(roofrays, V_outline);
F_roof = extract_faces_from_roofgraph(roofrays, E_roof, E_dual);
V_roof = roofgraph_Laplacian_embedding(V_ini, E_roof, V_outline);
end



function ray = construct_roofrays_from_outline(outline_edges, eid1, eid2, V, eps_ortho, eps_nndist)
% edgetype = 1: a roof edge, that connects an outline vtx with a roof vtx
% edgetype = 2: a ridge edge, that connects two roof vtx
% type = 1: the point of this ray cannot be changed!
% type = 2: the direction of this ray cannot be changed

if nargin < 4, eps_ortho = 1e-6; end
if nargin < 5, eps_nndist = 1e-6; end

normv = @(x) x/norm(x);
isParallel = @(e1, e2) 1 - abs(e1*e2') < eps_ortho;

ray = [];

% two outline edges
edge1 = outline_edges(eid1,:);
edge2 = outline_edges(eid2,:);

v11 = edge1(1:2);
v12 = edge1(3:4);
e1 = normv(v12 - v11);

v21 = edge2(1:2);
v22 = edge2(3:4);
e2 = normv(v22 - v21);

if isParallel(e1, e2)
    ray.edgetype = 2; % this is a ridge edge
    ray.type = 2; % the direction of this ray CANNOT be changed
    ray.direction = normv(e1 + sign(e1*e2')*e2);
    % the point position can be changed, by default we pick the middle
    ray.point = (v11 + v12 + v21 + v22)/4;
    ray.endpoints = nan(2,2);
    ray.vid = [];
else
    ray.type = 1; % the point cannot be changed
    % find the intersection
    x_intersect = find_intersection_of_two_lines(v11, e1, v21, e2, eps_ortho);
    x_all = [v11; v12; v21; v22];
    [vid, nn_dist] = knnsearch(x_all, x_intersect);
    if nn_dist/max(norm(v12-v11), norm(v22-v21)) < eps_nndist
        % the intersecting point is an outline vertex
        % this ray corresponds to a roof edge
        ray.edgetype = 1;
        ray.point = x_all(vid,:);
        ray.endpoints = [x_all(vid,:); nan(1,2)];
        ray.vid = find(ismember(V, ray.point,'rows'));
    else
        % this ray corresponds to a ridge edge
        ray.edgetype = 2;
        ray.point = x_intersect;
        ray.endpoints = [x_intersect; nan(1,2)];
        ray.vid = [];
    end
    ray.direction = [1,0]; % the direction of this ray can be changed
    
end
ray.oeid = [eid1,eid2];

end


function [x_intersect, a, b] = find_intersection_of_two_lines(x1,t1,x2,t2, eps_ortho)
if nargin < 5, eps_ortho = 1e-6; end
if 1 - abs(t1*t2') < eps_ortho % two lines are parallel to each other
%     warning('Computing intersection between two parallel lines!')
    x_intersect = [];
    a = [];  b = [];
else
    tmp = (x2-x1)/[t1;t2];
    a = tmp(1); b = -tmp(2);
    val = norm((x1 + a*t1) - (x2 + b*t2));
    if val > 1e-9
        error('Invalid intersection')
    end
    x_intersect = x1 + a*t1;
end
end

function [V_ini, E_roof, roofrays] = construct_roofgraph_from_roofrays(roofrays, V_outline)
num_ovtx = size(V_outline,1);
%------------------------------------------------------
% detect the intersections between rays (the roof vtx)
%------------------------------------------------------
intersections = detect_intersections_from_roofrays(roofrays);

%------------------------------------------------------
% find edges in the roof graph
%------------------------------------------------------
% assign random positions to the intersecting points (roof vertices)
x_new = rand(length(intersections),2);
% compute edges in the roof graph
V_ini = [V_outline; x_new];
E_tmp = [];
for intersect_id = 1:length(intersections)
    for rid = reshape(intersections(intersect_id).rayids,1, [])
        ray = roofrays(rid);
        if ray.edgetype == 1 % a roof edge
            E_tmp(end+1,:) = [ray.vid, num_ovtx + intersect_id];
            roofrays(rid).vid(end+1) = num_ovtx + intersect_id;
        else
            if isempty(ray.vid)
                roofrays(rid).vid = num_ovtx + intersect_id;
            else
                E_tmp(end+1,:) = [ray.vid, num_ovtx + intersect_id];
                roofrays(rid).vid(end+1) = num_ovtx + intersect_id;
            end
        end
    end
end
% collect the edge info from the roofrays
edges = [(1:num_ovtx)', [2:num_ovtx,1]'];
edges = [edges; E_tmp];
E_roof = unique([min(edges,[],2), max(edges,[],2)],'rows');
end



function F = extract_faces_from_roofgraph(roofrays, E_roof, E_dual)
% E_roof: edge list in the roof graph
% E_dual: edge list in the dual graph

E_roof = [min(E_roof,[],2), max(E_roof,[],2)];
unique_eids = unique(E_dual(:));
% for each outline edge, find its associated roof rays
associated_rids = arrayfun(@(eid)...
    find(arrayfun(@(ray)ismember(eid, ray.oeid), roofrays)),...
    unique_eids,'uni',0);

F = {};
for eid = 1:length(associated_rids)
    rids = associated_rids{eid};
    % vtxID in this face: un-ordered
    f = unique([roofrays(rids).vid]);
    count = ones(length(f),1);
    % we now order the vtx in f to form a valid polygon
    face = f(1);
    count(1) = 0;
    while true
        if length(face) == length(f)
            break;
        end
        vtx_cand = f(count > 0);
        edge = [repmat(face(end), length(vtx_cand),1), vtx_cand(:)];
        edge = [min(edge,[],2), max(edge,[],2)];
        select_eid = find(ismember(edge, E_roof,'rows'),1);
        select_vid = vtx_cand(select_eid);
        face(end+1) = select_vid;
        count(f == select_vid) = 0;
    end
    F{end+1} = face;
end
end



function V_all = roofgraph_Laplacian_embedding(V_ini, E_roof, V)
num_ovtx = size(V,1);
% compute the roof graph adjacency
A_roof = full(sparse(E_roof(:,1),E_roof(:,2),ones(size(E_roof,1),1), size(V_ini,1), size(V_ini,1)));
A_roof = A_roof + A_roof';
% compute the graph laplacian
L = diag(sum(A_roof)) - A_roof;

% update the roof vertex position to minimize the graph Laplacian
x0 = V_ini(num_ovtx+1:end,:);
x0 = reshape(x0,[],1);
func_lap = @(x) norm([V; reshape(x,[],2)]'*L*[V; reshape(x,[],2)],'fro');
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func_lap, x0, options);
V_all = [V; reshape(x,[],2)];
end



function intersections = detect_intersections_from_roofrays(roofrays)
func_findrid = @(edge, roofrays) find(arrayfun(@(ray)isequal(ray.oeid, edge) || isequal(ray.oeid,edge([2,1])), roofrays));
intersections = [];

while true
    check_rid = find([roofrays.count] > 0);
    if isempty(check_rid)
        break;
    end
    search_oeids = reshape([roofrays(check_rid).oeid],2,[])';
    
    all_nodes = {search_oeids(1,:)};
    
    all_nodes_new = {};
    while true
        for nid = 1:length(all_nodes)
            node = all_nodes{nid};
            
            vid = node(end,2);
            cand_rids = find(sum(ismember(search_oeids,vid),2));
            
            keep_rids = [];
            for j = reshape(cand_rids, 1, [])
                if ismember(search_oeids(j,:), node ,'rows') || ...
                        ismember(search_oeids(j,[2,1]), node,'rows')
                else
                    keep_rids(end+1) = j;
                end
            end
            
            
            for j = reshape(keep_rids, 1, [])
                node_tmp = node;
                if search_oeids(j,1) == vid
                    node_tmp(end+1,:) = search_oeids(j,:);
                else
                    node_tmp(end+1,:) = search_oeids(j,[2,1]);
                end
                
                all_nodes_new{end+1} = node_tmp;
            end
        end
        
        flag_find_intersection = false;
        for nid = 1:length(all_nodes_new)
            node = all_nodes_new{nid};
            if node(1,1) == node(end,2)
                flag_find_intersection = true;
                rayids = [];
                for ii = 1:size(node,1)
                    rid = func_findrid(node(ii,:), roofrays);
                    rayids(end+1) = rid;
                    roofrays(rid).count = roofrays(rid).count - 1;
                end
                x = struct();
                x.rayids = rayids;
                intersections = [intersections, x];
                break
            end
        end
        
        if ~flag_find_intersection
            all_nodes = all_nodes_new;
        else
            break;
        end
    end
end
end

