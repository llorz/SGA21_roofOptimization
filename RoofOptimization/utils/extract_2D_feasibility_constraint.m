function [vid_parallel_summary, vid_intersect_summary] = ...
    extract_2D_feasibility_constraint(obj, para)
% feasibility penalty:
% either parallel to the outline edges or intersect at the same point
eid_parallel = obj.eid_ridge(arrayfun(@(eid)obj.return_edge_edit_type(eid), obj.eid_ridge) == 1);
eid_intersect = obj.eid_ridge(arrayfun(@(eid)obj.return_edge_edit_type(eid), obj.eid_ridge) == 2);

% case 1: parallel
vid_parallel_summary = [];
for eid = reshape(eid_parallel,1,[])
    fids = obj.find_edge_neighboring_faces(eid);
    eid1 = obj.find_outline_edge_in_face(fids(1));
    e1 = obj.compute_edge_direction(eid1(1));
    vid_parallel_summary(end+1,:) = [obj.E(eid,:), e1];
end
% case 2: intersect 
vid_intersect_summary = [];
for eid = reshape(eid_intersect, 1, [])
    fids = obj.find_edge_neighboring_faces(eid);
    eid1 = obj.find_outline_edge_in_face(fids(1));
    eid2 = obj.find_outline_edge_in_face(fids(2));
    eid1 = eid1(1); eid2 = eid2(1);
    x1 = obj.V(obj.E(eid1,1),:);
    e1 = obj.compute_edge_direction(eid1);
    x2 = obj.V(obj.E(eid2,1),:);
    e2 = obj.compute_edge_direction(eid2);
    x_intersect = find_intersection_of_two_lines(x1, e1, x2, e2, para.eps_ortho);
    vid_intersect_summary(end+1,:) = [obj.E(eid,:), x_intersect];
end
end