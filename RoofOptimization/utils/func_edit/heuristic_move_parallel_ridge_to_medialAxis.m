function [obj_new] = heuristic_move_parallel_ridge_to_medialAxis(obj)

V1 = obj.V;
eid_parallel = obj.eid_ridge(arrayfun(@(eid)obj.return_edge_edit_type(eid), obj.eid_ridge) == 1);
% move parallel axis to the middle

% sort it w.r.t. the edge length
edge_length = arrayfun(@(eid)obj.compute_edge_length(eid), eid_parallel);
[~, id] = sort(edge_length,'descend');
eid_parallel_sorted = eid_parallel(id);

for eid = reshape(eid_parallel_sorted, 1, [])

    e_curr = obj.compute_edge_direction(eid);
    x_curr = obj.V(obj.E(eid,1),:);
    e_move = [e_curr(2), -e_curr(1)];
    
    fids = obj.find_edge_neighboring_faces(eid);
    
    eid1 = obj.find_outline_edge_in_face(fids(1));
    eid2 = obj.find_outline_edge_in_face(fids(2));
    eid1 = eid1(1); eid2 = eid2(1);
    x1 = obj.V(obj.E(eid1,1),:);
    x2 = obj.V(obj.E(eid2,1),:);
    
    d = norm(x2-x1 - ((x2 - x1)*e_curr')*e_curr);
    
    % let a = x_curr + t*e_move
    % norm(a-x1 - (a-x1)*e_curr'*e_curr) = d/2
    t0 = 0;
    func = @(t) norm(norm((x_curr + t*e_move - x1)*(eye(2) - e_curr'*e_curr)) - ...
        norm((x_curr + t*e_move - x2)*(eye(2) - e_curr'*e_curr)));
    options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
        'OptimalityTolerance',1e-12,...
        'FunctionTolerance',1e-12);
    t = fminunc(func, t0, options);
    
    V1(obj.E(eid,:),:) = V1(obj.E(eid,:),:) + t*e_move;
end

obj_new = RoofGraph(V1, obj.F);


end