% to regularize the outlines, we first categorize the outline edges into
% parallel set, then each outline edge has a fixed slanted angle
% we then update the positions of each outline vertex as the intersection
% of the two neighboring rays (start from the edge center, with a direction
% of the fixed angle)
% we need to carefully handle the vertex where the neighboring outline
% edges have the same orientation
function obj_new = regularize_outline_edges(obj,para)
if nargin < 2
    para.eps_ortho = 1e-3;
end

[edges_group, ~ , fixed_degrees] = category_outline_edges(obj);
func_groupID = @(eid)find(cellfun(@(x)ismember(eid,x),edges_group));


% % for the face with multiple parallel outline edges
% we fist fix their positions to make sure they are in the same line
check_fids = find(arrayfun(@(fid)length(obj.find_outline_edge_in_face(fid)),1:obj.nf) > 1);
V = obj.V;
if ~isempty(check_fids)
    for fid = reshape(check_fids,1,[])
        eids = obj.find_outline_edge_in_face(fid);
        if length(unique(arrayfun(@(eid) func_groupID(eid), eids))) == 1
            vids = reshape(obj.E(eids,:),1,[]);
            if ~isempty(setdiff(obj.F{fid}, vids))
                X = V(vids,:);
                theta = fixed_degrees(func_groupID(eids(1)));
                t = [cosd(theta), sind(theta)];
                center = mean(X);
                X_new = center + ((X - center)*t')*t;
                V(vids,:) = X_new;
            end
        end
    end
end

V_new = V;
V_ori = V;

% the neighboring outline edges of an outline vertex
vtx_neigh_eid = nan(obj.nv,2);
% the corresponding neighboring vertex id
vtx_neigh_vid = nan(obj.nv,2);
% the corresponding group ID of the neighboring outline edges
vtx_neigh_gid = nan(obj.nv,2);
for vid = 1:obj.nv
    if ismember(vid, obj.vid_outline)
        adj_eids = obj.eid_outline(sum(ismember(obj.E(obj.eid_outline,:), vid),2) == 1);
        
        if length(adj_eids) ~= 2
            obj_new = obj;
            warning('Cannot regularize the outline edges')
            return;
        end
        vtx_neigh_eid(vid,:) = adj_eids;
        for j = 1:2
            vtx_neigh_vid(vid,j) = setdiff(obj.E(adj_eids(j),:), vid);
        end
        vtx_neigh_gid(vid,:) = arrayfun(@(eid) func_groupID(eid), adj_eids);
    end
end

% find the corner vertex
corner_vid = obj.vid_outline(vtx_neigh_gid(obj.vid_outline,1) ~= vtx_neigh_gid(obj.vid_outline,2));

% find the "neighboring" corner vertex for each outline vertex
vtx_neigh_cvtx = nan(obj.nv,2);
for vid = reshape(obj.vid_outline, 1, [])
    
    neigh_vids = vtx_neigh_vid(vid,:);
    for kk = 1:2
        curr_vid = vid;
        next_vid = neigh_vids(kk);
        while ~ismember(next_vid, corner_vid)
            prev_vid = curr_vid;
            curr_vid = next_vid;
            next_vid = setdiff(vtx_neigh_vid(next_vid,:), prev_vid);
        end
        vtx_neigh_cvtx(vid, kk) = next_vid;
    end
end



for vid = reshape(corner_vid, 1, [])
    % edge orientation
    theta1 = fixed_degrees(vtx_neigh_gid(vid,1));
    theta2 = fixed_degrees(vtx_neigh_gid(vid,2));
    t1 = [cosd(theta1), sind(theta1)];
    t2 = [cosd(theta2), sind(theta2)];
    % center of the two corner vtx
    y1 = V_ori(vtx_neigh_cvtx(vid,1),:);
    y2 = V_ori(vtx_neigh_cvtx(vid,2),:);
    x1 = mean([y1; V_ori(vid,:)]);
    x2 = mean([y2; V_ori(vid,:)]);
    
    % compute the intersecting point of the two edges as the updated positions
    if 1-abs(t1*t2') < para.eps_ortho
        x = V_new(vid,:);
        V_new(vid,:) = x1 + ((x - x1)*t1')*t1;
    else
        V_new(vid,:) = find_intersection_of_two_lines(x1,t1,x2,t2);
    end
end

% fix the outline vtx that are not corner vtx
check_vid = setdiff(obj.vid_outline, corner_vid);
for vid = reshape(check_vid, 1, [])
    neigh_cvtx = vtx_neigh_cvtx(vid,:);
    d = sqrt(sum((V_ori(vid, :) - V_ori(neigh_cvtx,:)).^2,2));
    d = d./sum(d);
    V_new(vid,:) = (1-d(1))*V_new(neigh_cvtx(1),:) + d(1)*V_new(neigh_cvtx(2),:);
end

obj_new = obj;
obj_new.V = V_new;
end