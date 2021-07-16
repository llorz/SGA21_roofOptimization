function obj_new = split_face_at_two_vtx(obj, fid, vid1, vid2)
face = obj.F{fid};
inds = find(ismember(face,[vid1, vid2]));
face1 = face(inds(1):inds(2));
face2 = face([inds(2):length(face),1:inds(1)]);

obj.F(fid) = [];
obj.F{end+1} = face1;
obj.F{end+1} = face2;
obj_new = RoofGraph(obj.V, obj.F);
end