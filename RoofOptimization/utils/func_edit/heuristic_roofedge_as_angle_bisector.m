function [obj] = heuristic_roofedge_as_angle_bisector(obj, para, check_eid)
if nargin < 3
    candidate_eids = obj.eid_roof;
else
    candidate_eids = check_eid;
end
count = 1;
while count < 5
    [V, candidate_eids_next] = local_move_split_outline_angles(obj, candidate_eids, para);
    obj.V = V;
    if isequal(sort(candidate_eids), sort(candidate_eids_next))
        break;
    else
        candidate_eids = candidate_eids_next;
    end
    count = count + 1;
end
end

function [V, candidate_eids_next] = local_move_split_outline_angles(obj, candidate_eids, para)
scale = para.minEdgeLen/2;
normv = @(x) x/norm(x);
candidate_eids_next = [];
vtx_rays = split_angle_at_ouline_vertex(obj.V(obj.vid_outline,:));
V = obj.V;

while true
    if isempty(candidate_eids)
        break;
    end
    
    eid = candidate_eids(1);
    candidate_eids(1) = [];
    vids = obj.E(eid,:);
    vid_curr = vids(ismember(vids, obj.vid_roof));
    vid_outline = setdiff(vids, vid_curr);
    
    neigh_eids = obj.find_rvtx_neighboring_redges(vid_curr);
    check_neigh_eids = neigh_eids(ismember(neigh_eids, obj.eid_ridge));
    eid_check = check_neigh_eids(arrayfun(@(eid) obj.return_edge_edit_type(eid), check_neigh_eids) == 1);
    if length(eid_check) == 1
        ray1 = vtx_rays(vid_outline);
        % only adjacent to one parallel edge
        vid_other = setdiff(obj.E(eid_check,:),vid_curr);
        x2 = V(vid_other,:);
        t2 = normv(obj.V(vid_curr,:) - obj.V(vid_other,:));
        [flag, x_intersect] = find_intersection_of_two_rays(ray1.point, ray1.direction, x2, t2, para.eps_ortho);
        if flag
            if norm(x_intersect - x2) < scale
                V(vid_other, :) = x2 - scale*t2;
                V(vid_curr,:) = x_intersect + scale*t2;
            else
                V(vid_curr, :) = x_intersect;
            end
            candidate_eids = setdiff(candidate_eids, check_neigh_eids);
        else
            candidate_eids_next(end+1) = eid;
        end
        
    end
end
end
