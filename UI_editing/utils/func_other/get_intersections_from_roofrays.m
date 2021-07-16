function intersections = get_intersections_from_roofrays(roofrays)
func_associated_rayID = @(eid, all_roof_rays) find(arrayfun(@(ray) ismember(eid, ray.oeid), all_roof_rays));
func_findNeighRays = @(eid, roofrays) setdiff(unique([func_associated_rayID(roofrays(eid).oeid(1), roofrays),...
    func_associated_rayID(roofrays(eid).oeid(2), roofrays)]), eid);
func_findrid = @(edge, roofrays) find(arrayfun(@(ray)isequal(ray.oeid, edge) || isequal(ray.oeid,edge([2,1])), roofrays));
intersections = [];

while true
    check_rid = find([roofrays.count] > 0);
    if isempty(check_rid)
        break;
    end
    search_oeids = reshape([roofrays(check_rid).oeid],2,[])';
    
    all_nodes = {search_oeids(1,:)};
    
    all_nodes_new = {};
    while true
        for nid = 1:length(all_nodes)
            node = all_nodes{nid};
            
            vid = node(end,2);
            cand_rids = find(sum(ismember(search_oeids,vid),2));
            
            keep_rids = [];
            for j = reshape(cand_rids, 1, [])
                if ismember(search_oeids(j,:), node ,'rows') || ...
                        ismember(search_oeids(j,[2,1]), node,'rows')
                else
                    keep_rids(end+1) = j;
                end
            end
            
            
            for j = reshape(keep_rids, 1, [])
                node_tmp = node;
                if search_oeids(j,1) == vid
                    node_tmp(end+1,:) = search_oeids(j,:);
                else
                    node_tmp(end+1,:) = search_oeids(j,[2,1]);
                end
                
                all_nodes_new{end+1} = node_tmp;
            end
        end
        
        flag_find_intersection = false;
        for nid = 1:length(all_nodes_new)
            node = all_nodes_new{nid};
            if node(1,1) == node(end,2)
                flag_find_intersection = true;
                rayids = [];
                for ii = 1:size(node,1)
                    rid = func_findrid(node(ii,:), roofrays);
                    rayids(end+1) = rid;
                    roofrays(rid).count = roofrays(rid).count - 1;
                end
                x = struct();
                x.rayids = rayids;
                intersections = [intersections, x];
                break
            end
        end
        
        if ~flag_find_intersection
            all_nodes = all_nodes_new;
        else
            break;
        end
    end
end
% intersections = [];
% while(~isempty(find([roofrays.count] > 0, 1)))
%     for i = reshape(find([roofrays.count] > 0),1,[])
%         flag_findIntersection = false;
%         ray1 = roofrays(i);
%         eid_neigh = func_findNeighRays(i, roofrays);
%         eid_neigh = intersect(eid_neigh, find([roofrays.count] > 0));
%         for j = reshape(eid_neigh,1,[])
%             ray2 = roofrays(j);
%             tmp1 = intersect(ray1.oeid, ray2.oeid);
%             tmp2 = union(ray1.oeid, ray2.oeid);
%             edge = setdiff(tmp2, tmp1);
%             % check if this edge exists
%             rid = find(arrayfun(@(ray)isequal(ray.oeid, edge) || isequal(ray.oeid,edge([2,1])), roofrays));
%             if ~isempty(rid)
%                 x = struct();
%                 x.point = [ray1.oeid; ray2.oeid; roofrays(rid).oeid];
%                 x.rayids = [i, j, rid];
%                 intersections = [intersections, x];
%                 roofrays(i).count = roofrays(i).count - 1;
%                 roofrays(j).count = roofrays(j).count - 1;
%                 roofrays(rid).count = roofrays(rid).count - 1;
%                 flag_findIntersection = true;
%                 break;
%             end
%         end
%         if flag_findIntersection
%             break;
%         end
%     end
%     if ~flag_findIntersection
%         % the rest intersecting points have more than three adjacent edges
%
%     end
% end

end
