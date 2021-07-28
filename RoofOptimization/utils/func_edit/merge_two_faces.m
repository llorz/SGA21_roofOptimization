function obj_new = merge_two_faces(obj, ref_fid1, ref_fid2)
eid1 = obj.find_outline_edge_in_face(ref_fid1);
eid2 = obj.find_outline_edge_in_face(ref_fid2);
vids =reshape(obj.E([eid1, eid2],:),1,[]);

% todo: this need to be done in a clean way
% i.e,. just make sure these four points are in the same line
[~, axis_id] = min(var(obj.V(vids,:)));
obj.V(vids, axis_id) = obj.V(vids(1), axis_id);


face1 = obj.F{ref_fid1};
face2 = obj.F{ref_fid2};
vid_intersect = intersect(face1, face2);
if isempty(vid_intersect)
    error('not allowed to merget these two faces');
end
if length(vid_intersect) == 1
    num = obj.nv;
    V = obj.V;
    F = obj.F;
    V(end+1,:) = V(vid_intersect,:);
    new_vid = num+1;
    
    edges1 = [face1,face1([2:end,1])];
    edges2 = [face2,face2([2:end,1])];
    edges = [edges1; edges2];
    % we remove the four edges that connected to vid_intersect
    edges(sum(edges == vid_intersect,2) == 1,:) = [];
    % we create a new vertex at the intersecting vtx
    neigh_vids_tmp = obj.find_vtx_neighboring_vtxs(vid_intersect);
    neigh_vids = neigh_vids_tmp(ismember(neigh_vids_tmp, [face1(:); face2(:)]));
    vid1 = neigh_vids(1);
    if ismember(vid1, face1)
        check_vids = neigh_vids(ismember(neigh_vids, face2));
    else
        check_vids = neigh_vids(ismember(neigh_vids, face1));
    end
    
    
    % find the one in check_vids, that is adjacent to vid1
    eid1 = obj.return_edge_ID([vid1, vid_intersect]);
    eid2 = obj.return_edge_ID([check_vids(1), vid_intersect]);
    eid3 = obj.return_edge_ID([check_vids(2), vid_intersect]);
    fid1 = setdiff(obj.find_edge_neighboring_faces(eid1),[ref_fid1, ref_fid2]);
    fid2 = setdiff(obj.find_edge_neighboring_faces(eid2),[ref_fid1, ref_fid2]);
    fid3 = setdiff(obj.find_edge_neighboring_faces(eid3),[ref_fid1, ref_fid2]);
    
    if obj.is_two_face_adjacent(fid1, fid2)
        vid2 = check_vids(1);
        fid_update = [fid1, fid2];
    elseif obj.is_two_face_adjacent(fid1, fid3)
        vid2 = check_vids(2);
        fid_update = [fid1, fid3];
    else
        error('something is wrong!')
    end
    
    % they still connect to vid_intersect
    rest_vids = setdiff(neigh_vids, [vid1, vid2]);
    edges = [edges;...
        rest_vids(1), vid_intersect;...
        rest_vids(2), vid_intersect];
    % vid1 and vid2 are connected to the newly created vertex
    edges = [edges;...
        vid1, new_vid;...
        vid2, new_vid];
    
    % we first fix fid_update:
    for fid = fid_update
        face = obj.F{fid};
        face(face == vid_intersect) = new_vid;
        F{fid} = face;
    end
    % we then remove ref_fid1 and ref_fid2
    % and create a new face from edges
    F([ref_fid1, ref_fid2]) = [];
%     F(ref_fid2) = [];
    %
    edges = [min(edges,[],2), max(edges,[],2)];
    unique_vtx = unique(edges(:));
    count = ones(length(unique_vtx),1);
    face = unique_vtx(1);
    count(1) = 0;
    while true
        if isempty(find(count > 0,1))
            break;
        end
        v1 = face(end);
        candidate_vids = unique_vtx(count > 0);
        tmp_edges = [repmat(v1, length(candidate_vids),1), candidate_vids(:)];
        tmp_edges = [min(tmp_edges,[],2), max(tmp_edges,[],2)];
        eid = find(ismember(tmp_edges, edges,'rows'),1);
        v2 = setdiff(tmp_edges(eid,:), v1);
        count(unique_vtx == v2) = 0;
        face(end+1) = v2;
    end
    
    F{end+1} = face(:);
else
    % todo: handle the other cases
end

obj_new = RoofGraph(V, F);
end