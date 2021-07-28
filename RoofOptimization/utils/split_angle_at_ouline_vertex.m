function vtx_rays = split_angle_at_ouline_vertex(X)
% we assume the outline contour X is clock-wise pre-ordered
num = size(X,1);
vtxID_ref = repmat(1:num, 1, 3);
% equally split each angle
R = @(theta) [cos(theta) -sin(theta); sin(theta) cos(theta)];
vtx_rays = [];

outline_edges = [(1:num)',[(2:num)';1]];
func_findOid = @(edge) [find(ismember(outline_edges,edge,'rows')), find(ismember(outline_edges,edge([2,1]),'rows'))];

for vid = 1:num
    vtx_prev = X(vtxID_ref(num+vid-1),:);
    vtx_curr = X(vid,:);
    vtx_next = X(vtxID_ref(vid+1),:);
    
    e1 = vtx_prev - vtx_curr;
    e2 = vtx_next - vtx_curr;
    e1 = e1/norm(e1);
    e2 = e2/norm(e2);
    
    % We would like to sovle theta from R(theta)*e1 = e2
    % where R(theta) is the 2D rotation matrix, we then have
    % say e1 = (x1, y1), e2 = (x2, y2);
    % cos_t x1 - sin_t y1 = x2
    % sin_t x1 + cos_t y1 = y2
    
    A = [e1(1), -e1(2); e1(2), e1(1)];
    tmp = e2'\A;
    
    func = @(theta) (cos(theta) - tmp(1))^2 + (sin(theta) - tmp(2))^2;
    options = optimoptions(@fminunc,'Display','off');
    theta = fminunc(func, pi, options);
    
    theta = wrapTo2Pi(theta);
    
    t = R(theta/2)*e1';
    
    ray.point = vtx_curr;
    ray.direction = t';
    ray.vid = vid;
    ray.rid = vid;
    ray.next = vtxID_ref(vid+1);
    ray.prev = vtxID_ref(vid-1+num);
    ray.neigh_rid = [ray.prev, ray.next];
    ray.outline_edges = [[ray.prev, vid]; [ray.next, vid]];
    ray.outline_edges_id = [func_findOid([ray.prev, vid]), func_findOid([ray.next, vid])];
    ray.type = 1;
    vtx_rays = [vtx_rays, ray];

end
end