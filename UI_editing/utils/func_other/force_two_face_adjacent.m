function obj_new = force_two_face_adjacent(obj, ref_fid1, ref_fid2)
vid_intersect = intersect(obj.F{ref_fid1,:}, obj.F{ref_fid2,:});
if isempty(vid_intersect)
    
    vids = obj.F{ref_fid1};
    vids_f1 = vids(ismember(vids, obj.vid_roof));
    
    vids = obj.F{ref_fid2};
    vids_f2 = vids(ismember(vids, obj.vid_roof));
    
    
    % find the edge that connects two faces
    tmp1 = ismember(obj.E,vids_f1);
    tmp1(sum(tmp1,2) == 2,:) = 0;
    
    tmp2 = ismember(obj.E,vids_f2);
    tmp2(sum(tmp2,2) == 2,:) = 0;
    
    tmp =  tmp1 + tmp2;
    eid = find(tmp(:,1) == 1 & tmp(:,2) == 1);
    
    if ~isempty(eid)
        fids = obj.find_edge_neighboring_faces(eid);
        
        if length(obj.F{ref_fid1})  == 3 && length(obj.F{ref_fid2})  == 3
            % TODO: fix this
        elseif length(obj.F{ref_fid1})  == 3
            update_fid = ref_fid1;
            keep_fid = ref_fid2;
        elseif length(obj.F{ref_fid2}) == 3
            update_fid = ref_fid2;
            keep_fid = ref_fid1;
        else
            error('Try to snap the connecting edge e%d first', eid)
        end
        
        if length(obj.F{fids(1)}) < length(obj.F{fids(2)})
            mod_fid = fids(1);
        else
            mod_fid = fids(2);
        end
        adj_vids = intersect(obj.F{keep_fid}, obj.F{mod_fid});
        v1 = adj_vids(ismember(adj_vids,obj.E(eid,:))); % this one is kept in mod_fid
        v2 = setdiff(obj.E(eid,:), v1); % we remove v2 from mod_fid
        F = obj.F{mod_fid};
        F(F == v2) = [];
        obj.F{mod_fid} = F;
        
        start_vid = obj.F{update_fid}(ismember(obj.F{update_fid}, obj.F{mod_fid}));
        tmp = obj.F{update_fid}(ismember(obj.F{update_fid}, obj.vid_outline));
        end_vid = setdiff(tmp, start_vid);
        obj.F{update_fid} = [start_vid; v1;v2;end_vid];
        obj = RoofGraph(obj.V, obj.F);
        obj_new = force_two_face_adjacent_case1(obj,ref_fid1, ref_fid2);
    else
        error('Not allowed to merge these two faces');
    end
else
    obj_new = force_two_face_adjacent_case1(ref_fid1, ref_fid2);
end

end