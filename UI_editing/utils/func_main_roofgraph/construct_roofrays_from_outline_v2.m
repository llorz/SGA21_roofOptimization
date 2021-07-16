function ray = construct_roofrays_from_outline_v2(V, i, j, merge_eid, eps_ortho)
% edgetype = 1: a roof edge, that connects an outline vtx with a roof vtx
% edgetype = 2: a ridge edge, that connects two roof vtx
% type = 1: the point of this ray cannot be changed!
% type = 2: the direction of this ray cannot be changed

if nargin < 5, eps_ortho = 1e-6; end


normv = @(x) x/norm(x);
isParallel = @(e1, e2) 1 - abs(e1*e2') < eps_ortho;

num_vtx = size(V,1);
vtxRefID = repmat(1:num_vtx, 1, 3);


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
    ray.vid = [];
else
    ray.type = 1; % the point cannot be changed
    
    % theree exist faces that contain multiple faces
    ci = find(cellfun(@(x) ismember(i, x), merge_eid), 1);
    cj = find(cellfun(@(x) ismember(j, x), merge_eid), 1);
    
    if isempty(ci) && isempty(cj)
        % case 01: not face that contains multiple outline edges
        vid_intersect = intersect([i, vtxRefID(i+1)], [j, vtxRefID(j+1)]);
    else
        % case 02: there exist face that contains multiple outline edges
        if isempty(ci)
            eids = merge_eid{cj};
            vids = [eids, vtxRefID(eids+1)];
            vid_intersect = intersect(vids, [i, vtxRefID(i+1)]);
        else
            eids = merge_eid{ci};
            vids = [eids, vtxRefID(eids+1)];
            vid_intersect = intersect(vids, [j, vtxRefID(j+1)]);
        end
    end
    
    if ~isempty(vid_intersect)
        % the intersecting point is an outline vertex
        % this ray corresponds to a roof edge
        ray.edgetype = 1;
        ray.point = V(vid_intersect,:);
        ray.vid = vid_intersect;
    else
        % this ray corresponds to a ridge edge
        ray.edgetype = 2;
        x_intersect = find_intersection_of_two_lines(v11, e1, v21, e2, eps_ortho);
        ray.point = x_intersect;
        ray.vid = [];
    end
    ray.endpoints = [ray.point; nan(1,2)];
    ray.direction = [1,0]; % the direction of this ray can be changed
    
end

ray.oeid = [i,j];

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

