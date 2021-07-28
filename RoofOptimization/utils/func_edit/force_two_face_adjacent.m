function obj_new = force_two_face_adjacent(obj, ref_fid1, ref_fid2)
vid_intersect = intersect(obj.F{ref_fid1,:}, obj.F{ref_fid2,:});
if isempty(vid_intersect)
    error('Not allowed to merge these two faces');
end
eids = obj.find_rvtx_neighboring_redges(vid_intersect);

if length(eids) ==  2
    if ismember(ref_fid1, obj.find_edge_neighboring_faces(eids(1)))
        merge_eid1 = eids(1);
        merge_eid2 = eids(2);
    else
        merge_eid1 = eids(2);
        merge_eid2 = eids(1);
    end
else
    % todo: find the correct ridge to merge
end

vids = setdiff(reshape(obj.E([merge_eid1, merge_eid2],:),1,[]), vid_intersect);
vid_rm = vids(1);
vid_kp = vids(2);
%%
% for the faces that contains these two edges, should remove the connection
% to vid_intersect
F = obj.F;
fids1 = obj.find_edge_neighboring_faces(merge_eid1);
fids2 = obj.find_edge_neighboring_faces(merge_eid2);
check_fids = setdiff([fids1, fids2], [ref_fid1, ref_fid2]);

for fid = reshape(check_fids,1, [])
    face = F{fid};
    face(face == vid_intersect) = [];
    face(face == vid_rm) = vid_kp;
    F{fid} = face;
end

for fid = reshape(obj.find_vtx_neighboring_faces(vid_rm), 1, [])
    face = F{fid};
    face(face == vid_rm) = vid_kp;
    F{fid} = face;
end

obj_new = RoofGraph(obj.V, F);

end