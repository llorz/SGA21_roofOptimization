function [V_ini, E_roof, roofrays] = construct_roofgraph_from_roofrays(roofrays, V_outline)
num_ovtx = size(V_outline,1);
%------------------------------------------------------
% detect the intersections between rays (the roof vtx)
%------------------------------------------------------
intersections = detect_intersections_from_roofrays(roofrays);

%------------------------------------------------------
% find edges in the roof graph
%------------------------------------------------------
% assign random positions to the intersecting points (roof vertices)
x_new = rand(length(intersections),2);
% compute edges in the roof graph
V_ini = [V_outline; x_new];
E_tmp = [];
for intersect_id = 1:length(intersections)
    for rid = reshape(intersections(intersect_id).rayids,1, [])
        ray = roofrays(rid);
        if ray.edgetype == 1 % a roof edge
            E_tmp(end+1,:) = [ray.vid, num_ovtx + intersect_id];
            roofrays(rid).vid(end+1) = num_ovtx + intersect_id;
        else
            if isempty(ray.vid)
                roofrays(rid).vid = num_ovtx + intersect_id;
            else
                E_tmp(end+1,:) = [ray.vid, num_ovtx + intersect_id];
                roofrays(rid).vid(end+1) = num_ovtx + intersect_id;
            end
        end
    end
end
% collect the edge info from the roofrays
edges = [(1:num_ovtx)', [2:num_ovtx,1]'];
edges = [edges; E_tmp];
E_roof = unique([min(edges,[],2), max(edges,[],2)],'rows');
end
