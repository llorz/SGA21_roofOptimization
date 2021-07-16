function [roofrays, F, intersections, V_all] = construct_roofrays_from_adjacency_graph(V, A, eps_ortho)
% INPUT:
%      V: the ordered n outline vertices (in clockwise order)
%           we assume the i-th edge has the endponts of (i, i+1)
%           the i-th face contains the i-th edge
%      A: the adjacency matrix, with size n-by-n, where
%           A(i,j) = 1: the i-th face is adjacent to the j-th face
% Optional input:
%      that multiple outline edges can be in the same face

% every two adjacent faces have an intersection line
% (might exist multiple intersecting edges though)

if nargin < 3, eps_ortho = 1e-6; end
% type1: direction can be changed
% type2: point can be changed
% type3: both direction and point are fixed
num_ovtx = size(V,1);
vtxRefID = repmat(1:num_ovtx, 1, 3);


[i,j] = ind2sub(size(A),find(A));
% the adjacency information
E = [i,j];
E = [min(E,[],2), max(E,[],2)];
E = unique(E,'rows');
% the ridge edges can be used twice
roofrays = [];
for i = 1:size(E,1)
    e1 = E(i,1);
    e2 = E(i,2);
    ray = construct_ray_from_two_outline_edges(V, e1, e2, eps_ortho);
    if length(unique([e1, vtxRefID(e1+1), e2, vtxRefID(e2+1)])) == 4
        % this is a roof ridge (two endpoints are roof vertices)
        ray.count = 2;
    else
        % this is a roof edge (with one endpoint as the outline vertex)
        ray.count = 1;
    end
    roofrays = [roofrays, ray];
end

%------------------------------------------------------
% detect the intersections between rays
intersections = get_intersections_from_roofrays(roofrays);

%------------------------------------------------------
% construct faces from the intersections

F = cell(num_ovtx, 1);
% for each outline edge, find its associated roof rays
associated_rids = arrayfun(@(eid)...
    find(arrayfun(@(ray)ismember(eid, ray.oeid), roofrays)),...
    1:size(V,1),'uni',0);
% each outline edge leads to a face: find the ordered vtx ids for each face
for eid = 1:num_ovtx
    % first order the assocated roof rays
    rids = associated_rids{eid};
    edge = [eid, vtxRefID(eid+1)];
    % we start with the roof edge that connects to the endpoint (eid+1)
    curr_rid = rids(arrayfun(@(ray) sum(ismember(edge, ray.oeid)), roofrays(rids)) == 2);
    check_rid = setdiff(rids, curr_rid);
    rids_orderd = [curr_rid]; % the ordered rays
    f = [vtxRefID(eid+1)]; % face: that stores the ordered vtxID
    while(~isempty(check_rid))
        for rid = reshape(check_rid, 1, [])
            intersect_id = find(arrayfun(@(x) sum(ismember([curr_rid, rid], x.rayids)), intersections) == 2);
            if ~isempty(intersect_id)
                % we then know curr_rid and rid intersects with each other
                % at this point
                vid = intersect_id + num_ovtx;
                roofrays(rid).vid(end+1) = vid;
                roofrays(curr_rid).vid(end+1) = vid;
                rids_orderd(end+1) = rid; % add this ray_id to the ordered list
                check_rid = setdiff(check_rid, rid); % remove it from the check list
                curr_rid = rid; % set it to the current ray_id
                f(end+1) = intersect_id + num_ovtx; % add the intersecting point ID
                break;
            end
        end
    end
    f(end+1) = eid;
    F{eid} = f;
end

% update the vtxID of the endpoints for each roof rays
for rid = 1:length(roofrays)
    roofrays(rid).vid = unique(roofrays(rid).vid);
end
for rid = reshape(find([roofrays.edgetype] == 1),1,[])
    oeid = roofrays(rid).oeid;
    roofrays(rid).vid(end+1) = intersect([oeid(1), vtxRefID(oeid(1)+1)], [oeid(2), vtxRefID(oeid(2)+1)]);
end

% initialize the roof vertex as the center of the adjacent rays
V_roof = cell2mat(arrayfun(@(x) mean(reshape([roofrays(x.rayids).point],2,[])'), intersections,'uni',0)');
V_all = [V; V_roof];
V_all = get_initial_graph_layout_by_Laplacian(V, F, V_all);
end


function intersections = get_intersections_from_roofrays(roofrays)
func_associated_rayID = @(eid, all_roof_rays) find(arrayfun(@(ray) ismember(eid, ray.oeid), all_roof_rays));
func_findNeighRays = @(eid, roofrays) setdiff(unique([func_associated_rayID(roofrays(eid).oeid(1), roofrays),...
    func_associated_rayID(roofrays(eid).oeid(2), roofrays)]), eid);
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
% intersections = [];
% while(~isempty(find([roofrays.count] > 0, 1)))
%     for i = reshape(find([roofrays.count] > 0),1,[])
%         flag_findIntersection = false;
%         ray1 = roofrays(i);
%         eid_neigh = func_findNeighRays(i, roofrays);
%         eid_neigh = intersect(eid_neigh, find([roofrays.count] > 0));
%         for j = reshape(eid_neigh,1,[])
%             ray2 = roofrays(j);
%             tmp1 = intersect(ray1.oeid, ray2.oeid);
%             tmp2 = union(ray1.oeid, ray2.oeid);
%             edge = setdiff(tmp2, tmp1);
%             % check if this edge exists
%             rid = find(arrayfun(@(ray)isequal(ray.oeid, edge) || isequal(ray.oeid,edge([2,1])), roofrays));
%             if ~isempty(rid)
%                 x = struct();
%                 x.point = [ray1.oeid; ray2.oeid; roofrays(rid).oeid];
%                 x.rayids = [i, j, rid];
%                 intersections = [intersections, x];
%                 roofrays(i).count = roofrays(i).count - 1;
%                 roofrays(j).count = roofrays(j).count - 1;
%                 roofrays(rid).count = roofrays(rid).count - 1;
%                 flag_findIntersection = true;
%                 break;
%             end
%         end
%         if flag_findIntersection
%             break;
%         end
%     end
%     if ~flag_findIntersection
%         % the rest intersecting points have more than three adjacent edges
%
%     end
% end

end


function V_all = get_initial_graph_layout_by_Laplacian(V, F, V_all)
num_ovtx = size(V,1);
X = V_all;
% get the connectivity graph from the faces
edges = [];
for fid = 1:length(F)
    face = reshape(F{fid},[],1);
    edges = [edges; face, face([2:length(face),1])];
end
E = unique([min(edges,[],2), max(edges,[],2)],'rows');

A_vtx = full(sparse(E(:,1),E(:,2),ones(size(E,1),1), size(X,1), size(X,1)));
A_vtx = A_vtx + A_vtx';
% compute the graph laplacian
L = diag(sum(A_vtx)) - A_vtx;

x0 = V_all(num_ovtx+1:end,:);
x0 = reshape(x0,[],1);

func_lap = @(x) norm([V; reshape(x,[],2)]'*L*[V; reshape(x,[],2)],'fro');
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func_lap, x0, options);
V_all = [V; reshape(x,[],2)];
end