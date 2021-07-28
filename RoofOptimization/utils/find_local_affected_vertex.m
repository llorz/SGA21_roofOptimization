function var_vid = find_local_affected_vertex(obj, ini_vid)

var_vid = []; % the variable vertex
is_vtx_checked(ini_vid) = 1;
check_vids = ini_vid;

while ~isempty(check_vids)
    
    curr_vid = check_vids(1);
    check_vids(1) = [];
    neigh_vids = obj.find_vtx_neighboring_vtxs(curr_vid);
    new_check_vids = neigh_vids(ismember(neigh_vids, obj.vid_roof));
    new_check_vids = setdiff(new_check_vids, find(is_vtx_checked));
    keep_check_vids = [];
    for mod_vid = reshape(new_check_vids, 1, [])
        is_vtx_checked(mod_vid) = 1;
        
        eid = obj.return_edge_ID([curr_vid, mod_vid]);
        edit_type = obj.return_edge_edit_type(eid);
        
        if edit_type == 1 % the direction cannot be changed, but the point can be changed
            if curr_vid == ini_vid
                var_vid(end+1) = mod_vid;
                keep_check_vids(end+1) = mod_vid;
            end
        elseif edit_type == 2 % the point cannot be changed, but the direction can be changed
            keep_check_vids(end+1) = mod_vid;
            var_vid(end+1) = mod_vid;
        end
        
    end
    
    check_vids = [check_vids(:); keep_check_vids(:)];
end

var_vid = unique(var_vid);
end