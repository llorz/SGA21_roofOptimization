function X = construct_roof_greedy(obj, vtx_type, roof_height)
if nargin < 3, roof_height = 100; end

X = [obj.V, zeros(obj.nv,1)];
X_isfixed = zeros(obj.nv,1);
X_isfixed(vtx_type == 1) = 1;

% fix the height of a random roof vertex
[~, id] = max(arrayfun(@(vid)length(obj.find_rvtx_neighboring_redges(vid)), obj.vid_roof));
vid = obj.vid_roof(id);
% vid = find(vtx_type == 2, 1);
X(vid, 3) = roof_height;
X_isfixed(vid) = 1;

% solve the other roof vertex by planarity constraint
F = obj.F;

num_ovids = cellfun(@(face) length(find(vtx_type(face) == 1)), F);
count = 1;
while (count <= 100)
    num_vars = cellfun(@(face) length(find(X_isfixed(face) == 0)), F);
    num_fixed_rvids = cellfun(@(face) length(find(X_isfixed(face(vtx_type(face) == 2)) == 1)), F);
    
    candidate_fids = find((num_fixed_rvids + num_ovids >= 3) & ...
        num_vars > 0 & ...
        num_fixed_rvids >= 1);
    
    [~, id] = max(num_vars(candidate_fids));
    fid = candidate_fids(id);
    if isempty(fid)
        vid = find(X_isfixed == 0, 1);
        fids = obj.find_vtx_neighboring_faces(vid);
        % all the neighboring faces are triangles
        if isempty(find(arrayfun(@(fid) length(obj.F{fid}), fids) ~= 3,1))
            vids = obj.find_vtx_neighboring_vtxs(vid);
            vids = vids(vtx_type(vids) ~= 1);
            if isempty(vids)
                X(vid,3) = roof_height;
            else
                X(vid,3) = mean(X(vids,3));
            end
        else %
            X(vid,3) = roof_height;
        end
        X_isfixed(vid) = 1;
    else
        vid = F{fid};
        V = X(vid,:); % face
        flag = X_isfixed(vid);
        X(vid, :) = flatten_face(V, flag);
        X_isfixed(vid) = 1;
    end
    
    if isempty(find(X_isfixed == 0,1))
        break;
    end
    count = count + 1;
end
end