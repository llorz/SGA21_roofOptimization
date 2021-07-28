function obj2 = remove_ridge_edge(obj, rm_eid)
if ~ismember(rm_eid, obj.eid_ridge)
    error('we are only allowed to remove an ridge edge')
end
% the endpoints of this edge
vids = obj.E(rm_eid,:);
% we plan to remove the second endpoint to remove this edge
vid_kp = vids(1);
vid_rm = vids(2);
F = obj.F;
V = obj.V;
neigh_fids = obj.find_vtx_neighboring_faces(vid_rm);
for fid = reshape(neigh_fids, 1, [])
    face = F{fid};
    if ismember(vid_kp, face)
        % this edge belong to this face
        % we can simply remove the rm_vid
        face(face == vid_rm) = [];
    else
        % we replace vid_rm by vid_keep
        face(face == vid_rm) = vid_kp;
    end
    F{fid} = face;
end
% we will then leave vid_rm unreferenced, which will be removed
% automatically when creating the roof graph
obj2 = RoofGraph(V, F);

end