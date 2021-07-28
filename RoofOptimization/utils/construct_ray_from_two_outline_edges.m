function ray = construct_ray_from_two_outline_edges(V, i, j, eps_ortho)
if nargin < 4
    eps_ortho = 1e-6;
end

num_vtx = size(V,1);
vtxRefID = repmat(1:num_vtx, 1, 3);

normv = @(x) x/norm(x);
isParallel = @(e1, e2) 1 - abs(e1*e2') < eps_ortho;

ray = [];

% two outline edges
v11 = V(i,:);
v12 = V(vtxRefID(i+1),:);
e1 = normv(v12 - v11);

v21 = V(j,:);
v22 = V(vtxRefID(j+1),:);
e2 = normv(v22 - v21);

if isParallel(e1, e2)
    ray.edgetype = 2; % this is a ridge edge
    ray.type = 2; % the direction of this ray CANNOT be changed
    ray.direction = normv(e1 + sign(e1*e2')*e2);
    % the point position can be changed, by default we pick the middle
    ray.point = (v11 + v12 + v21 + v22)/4;
    ray.endpoints = nan(2,2);
else
    ray.type = 1; % the point cannot be changed
    
    if vtxRefID(i+1) == j
        ray.edgetype = 1; % this is a roof edge
        x_intersect = V(j,:);
        
        vtx_prev = V(i,:);
        vtx_curr = V(vtxRefID(i+1),:);
        vtx_next = V(vtxRefID(j+1),:);
        e = compute_angle_bisector(vtx_prev, vtx_curr, vtx_next);
    elseif vtxRefID(j+1) == i
        ray.edgetype = 1; % roof edge
        x_intersect = V(i,:);
        
        vtx_prev = V(j,:);
        vtx_curr = V(vtxRefID(j+1),:);
        vtx_next = V(vtxRefID(i+1),:);
        %         e = compute_angle_bisector(vtx_prev, vtx_curr, vtx_next);
        e = [0,1];
    else
        ray.edgetype = 2; % ridge edge
        % two outline edges are not adjacent to each other
        [x_intersect, c1] = find_intersection_of_two_lines(v11, e1, v21, e2, eps_ortho);
        
        vtx_curr = x_intersect;
        vtx_prev = V(i,:);
        vtx_next = V(j,:);
        if c1 < 0
            vtx_prev = V(j,:);
            vtx_next = V(i,:);
        end
        %         e = compute_angle_bisector(vtx_prev, vtx_curr, vtx_next);
        e = [0,1];
    end
    
    ray.direction = e;
    ray.point = x_intersect;
    ray.endpoints = [x_intersect; nan(1,2)];
end
ray.oeid = [i,j];
ray.vid = [];
end