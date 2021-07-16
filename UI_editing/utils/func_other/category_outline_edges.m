% category the edges into sets
% each set contains the edges that is parallel to a border edge
function [edges_group, fixed_angles, fixed_degrees] = category_outline_edges(obj)
eps_ortho = 1-cosd(obj.eps_degree);
V = obj.V;
E = obj.E;
edges_group = {};

eid_outline = obj.eid_outline;
check_eid = eid_outline;
eid_search = eid_outline;
while (true)
    eid = check_eid(1);
    % find all edges that is parrallel to this edge
    tmp1 = (V(E(eid_search,1),:) - V(E(eid_search,2),:));
    tmp2 = sqrt(sum(tmp1.^2,2));
    tmp = tmp1./tmp2;
    e = V(E(eid,1),:) - V(E(eid,2),:);
    e = e/norm(e);
    eid_par = eid_search(1 - abs(tmp*e') < eps_ortho);
    edges_group{end+1} = eid_par;
    check_eid = setdiff(check_eid, eid_par);
    eid_search = setdiff(eid_search, eid_par);
    if isempty(check_eid)
        break;
    end
end

if nargout > 1
    % compute the angles for each edge group
    fixed_degrees = zeros(length(edges_group),1);
    for i_group = 1:length(edges_group)
        eids = edges_group{i_group};
        tmp_angle = [];
        for id = reshape(eids,1,[])
            x1 = V(E(id,1),:);
            x2 = V(E(id,2),:);
            
            
            e1 = x1 - x2;
            e1 = e1/norm(e1);
            if abs(e1*[1,0]') > 1 - eps_ortho
                tmp_angle(end+1) = 0;
            else
                if x2(2) > x1(2)
                    e1 = -e1;
                end
                tmp_angle(end+1) = acos(e1*[1,0]');
            end
           
        end
        angle = mean(tmp_angle);
        degree = angle/(2*pi)*360;
        fixed_degrees(i_group) = round(degree/obj.eps_degree)*obj.eps_degree;
    end
    fixed_angles = fixed_degrees/180*pi;
end
end

