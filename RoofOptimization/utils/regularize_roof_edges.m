function obj_new = regularize_roof_edges(obj)
%% first find the roof edges that are parallel to the outline edges
[edges_group, ~ , fixed_degrees] = category_outline_edges(obj);
func_groupID = @(eid)find(cellfun(@(x)ismember(eid,x),edges_group));

parallel_reids = [];

% we store the candidate ray for each roof edge
% besides the point and direction of the ray
% we also category the rays into three types
% 1: for this type of rays, the direction cannot be changed but the start
% point can be changed (they are parallel to the outline edges)
% 2: for this type of rays, the start point is fixed to the intersection of
% the two neighboring outline edges, but the direction can be updated
% 3: both the starting point and the direction can be changed, this type of
% outline edges is adjacent to a triangle face
roof_edge_ray = cell(obj.ne,1);

for eid = reshape(obj.eid_ridge,1,[])
    fids = obj.find_edge_neighboring_faces(eid);
    eid1 = obj.find_outline_edge_in_face(fids(1));
    eid2 = obj.find_outline_edge_in_face(fids(2));
    
    % eid1/eid2 can be empty for a triangle face
    if ~isempty(eid1) && ~isempty(eid2)
        % a face can have multiple parallel outline edges
        eid1 = eid1(1);
        eid2 = eid2(1);
        
        gid1 = func_groupID(eid1);
        gid2 = func_groupID(eid2);
        if gid1 == gid2 % two outline edges are parallel to each other
            parallel_reids = [parallel_reids;...
                eid, gid1];
        else
            % if two outline edges are not parallel
            % we can determine the lines where the roof edge lies in
            edge1 = obj.V(obj.E(eid1,:),:);
            edge2 = obj.V(obj.E(eid2,:),:);
            
            t1 = obj.compute_edge_direction(eid1);
            t2 = obj.compute_edge_direction(eid2);
            x1 = obj.V(obj.E(eid1,1),:);
            x2 = obj.V(obj.E(eid2,1),:);
            
            x_intersect = find_intersection_of_two_lines(x1, t1, x2, t2);
            center = mean(obj.V(obj.E(eid,:),:));
            t = center - x_intersect;
            t = t/norm(t);
            
            roof_edge_ray{eid}.point = x_intersect;
            roof_edge_ray{eid}.direction = t;
            roof_edge_ray{eid}.type = 2; % the start point of the ray cannot be changed
        end
    else
        edge = obj.V(obj.E(eid,:),:);
        
        roof_edge_ray{eid}.point = mean(edge);
        roof_edge_ray{eid}.direction = obj.compute_edge_direction(eid);
        roof_edge_ray{eid}.type = 3; 
    end
end
%% check if two adjacent roof edges have the same orientation
num = size(parallel_reids,1);
% the adjacent matrix of the roof edges
% if two edges are adjacent && have the same orientation
A = zeros(num);
for i = 1:num-1
    for j = i+1:num
        eid1 = parallel_reids(i,1);
        eid2 = parallel_reids(j,1);
        
        gid1 = parallel_reids(i,2);
        gid2 = parallel_reids(j,2);
        
        if obj.check_if_two_edges_adjacent(eid1,eid2) && gid1 == gid2
            A(i,j) = 1; A(j,i) = 1;
        end
    end
end
% the Laplacian of the adjacent matrix
L = diag(A*ones(num,1)) - A;
ic = conncomp(L); % the connected components

% for each connected component, we first determine the lines where these
% roof edges are lying in
for i = 1:length(unique(ic))
    reids = parallel_reids(ic == i,1);
    vids = unique(reshape(obj.E(reids,:),1,[]));
    x = mean(obj.V(vids,:));
    theta = fixed_degrees(parallel_reids(find(ic==i,1), 2));
    t = [cosd(theta), sind(theta)];
    
    for j = reshape(reids,1,[])
        roof_edge_ray{j} = struct('point', x, 'direction', t,...
            'type', 1); % the direction of these rays cannot be changed
    end
end
%% we update the positions of the roof vertex by the intersection of the rays
V_new = obj.V;
V_prev = obj.V;
count = 1;
fprintf('Updating the roof vertices...');
while (count < 10)
    fprintf('%d...', count);
    for rvid = reshape(obj.vid_roof, 1, [])
        reids = obj.find_rvtx_neighboring_redges(rvid);
        if length(reids) > 1
            val = inf(length(reids),1);
            e1 = obj.compute_edge_direction(reids(1));
            for kk = 2:length(reids)
                e2 = obj.compute_edge_direction(reids(kk));
                val(kk) = abs(e1*e2');
            end
            [~, select_eid] = min(val);
            
            ray1 = roof_edge_ray{reids(1)};
            ray2 = roof_edge_ray{reids(select_eid)};
            
            x_new = find_intersection_of_two_lines(ray1.point, ray1.direction, ray2.point, ray2.direction);
            V_new(rvid,:) = x_new;
            
            % update the rays w.r.t. the updated vertex
            for kk = reshape(reids,1, [])
                if roof_edge_ray{kk}.type ~= 2
                    % for type 1,3, we update the starting point of the ray
                    roof_edge_ray{kk}.point = x_new;
                elseif roof_edge_ray{kk}.type ~= 1
                    % for type 2,3, we update the direction of the ray
                    t = x_new - roof_edge_ray{kk}.point;
                    t = t/norm(t);
                    roof_edge_ray{kk}.direction = t;
                end
            end
        elseif length(reids) == 1 % simply project
            % if it is only connected to one roof edge
            % just project the original position to the correct roof edge
            ray = roof_edge_ray{reids(1)};
            x = V_new(rvid, :);
            dist = (x - ray.point)*ray.direction';
            x_new = ray.point + dist*ray.direction;
            V_new(rvid,:) = x_new;
        end
    end
    if isequal(V_new, V_prev)
        break;
    else
        V_prev = V_new;
    end
    count = count + 1;
end
fprintf('\n');
obj_new = obj;
obj_new.V = V_new;
end