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

