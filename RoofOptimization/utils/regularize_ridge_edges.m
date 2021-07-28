function obj_new = regularize_ridge_edges(obj, para)

X_new = obj.V;
NormVec = @(x) x / norm(x);
%--------------------------------------------------------
%  Update ROOF vertex positions
%--------------------------------------------------------
% we will update the vertex positions of the roof vertex
X_isfixed = ones(obj.nv,1);
X_isfixed(obj.vid_roof) = 0; % we are trying to update the roof vertices
X_isfixed(obj.vid_roof(ismember(obj.vid_roof,obj.E(obj.eid_ridge,:)) == 0)) = 1;
% if type = 1: parallel to outline edges
% if type = 2: intersect with outline edge
ridgeEdge_types = nan(obj.ne, 1);
% for type 2 cases: also store the two face IDs, whose outline edges will
% be affected by this ridge edge
ridgeEdge_face_ids = nan(obj.ne, 2);
reid_vids = reshape(obj.E(obj.eid_ridge,:),[],1);
freq = arrayfun(@(x) length(find(reid_vids == x)),reid_vids);

% start with a roof vertex that only connects to ONE ridge edge
% vid_curr = reid_vids(find(freq == 1, 1));

% start with the shortest roof vertex that only connects to one ridge edge
candidate_vids = reid_vids(freq == 1);
len = arrayfun(@(vid)obj.compute_edge_length(obj.eid_ridge(sum(ismember(obj.E(obj.eid_ridge,:), vid),2)==1)),...
    candidate_vids);
[~, id] = min(len);
vid_curr = candidate_vids(id);

X_isfixed(vid_curr) = 1;
count = 1;
while(count < 100)
    % for a ridge where one of the endpoint is fixed
    reid_curr = obj.eid_ridge(find(sum(X_isfixed(obj.E(obj.eid_ridge,:)),2) == 1,1));
    if ~isempty(reid_curr)
        face_ids = obj.find_edge_neighboring_faces(reid_curr);
        % two outline edges of the adjacent faces
        eid1 = obj.find_outline_edge_in_face(face_ids(1));
        eid2 = obj.find_outline_edge_in_face(face_ids(2));
        
        vids = obj.E(reid_curr,:);
        vid_fixed = vids(X_isfixed(vids) == 1);
        vid_free = setdiff(vids, vid_fixed);
        x_curr = X_new(vid_fixed,:);
        
        if ~isempty(eid1) && ~isempty(eid2)
            eid1 = eid1(1); eid2 = eid2(1);
            % find the directions of the outline edges
            e1 = obj.compute_edge_direction(eid1);
            e2 = obj.compute_edge_direction(eid2);

            if 1 - abs(e1*e2') < para.eps_ortho % two outlines parallel to each other
                e = e1;
                ridgeEdge_types(reid_curr) = 1;
            else
                x1 = obj.V(obj.E(eid1,1),:);
                x2 = obj.V(obj.E(eid2,1),:);
                x_intersect = find_intersection_of_two_lines(x1, e1, x2, e2);
                e = x_intersect - x_curr;
                e = e/norm(e);
                ridgeEdge_types(reid_curr) = 2;
                ridgeEdge_face_ids(reid_curr,:) = face_ids;
            end
            % we project the point to the line start from vid_fixed, with direction e
            x1 = X_new(vid_fixed,:);
            x2 = X_new(vid_free,:);
            X_new(vid_free,:) = x1 + ((x2 - x1)*e')*e;
            X_isfixed(vid_free) = 1;
        else
            % one face does not have an outline edge, i.e., degenerated face
            if isempty(eid1)
                fid_check = face_ids(1);
                fid_good = face_ids(2);
            else
                fid_check = face_ids(2);
                fid_good = face_ids(1);
            end
            neigh_fids = obj.find_neighboring_faces_of_input_face(fid_check);
            neigh_fids = setdiff(neigh_fids, fid_good);
            isFree = true;
            for fid = reshape(neigh_fids, 1, [])
                [~, shared_eid] = obj.is_two_face_adjacent(fid_check, fid);
                e1 = obj.compute_edge_direction(shared_eid);
                oeids = obj.find_outline_edge_in_face(fid);
                if ~isempty(oeids)
                    e2 = obj.compute_edge_direction(oeids(1));
                    x2 = obj.V(obj.E(oeids(1),1),:);
                    if 1 - abs(e1*e2') < para.eps_ortho
                        % if the shared edge is parallel to the outline edge of
                        % the adjacent face
                        eid1 = obj.find_outline_edge_in_face(fid_good);
                        if ~isempty(eid1)
                            e3 = obj.compute_edge_direction(eid1(1));
                            x3 = obj.V(obj.E(eid1(1),1),:);
                            if 1 - abs(e3*e2') > para.eps_ortho
                                % if the two outline edges of fid_good and fid are
                                % not parallel
                                x_intersect = find_intersection_of_two_lines(x2, e2, x3, e3);
                                e = x_intersect - x_curr;
                                e = e/norm(e);
                                ridgeEdge_types(reid_curr) = 2;
                                ridgeEdge_face_ids(reid_curr, :) = [fid_good, fid];
                                
                                % we project the point to the line start from vid_fixed, with direction e
                                x1 = X_new(vid_fixed,:);
                                x2 = X_new(vid_free,:);
                                X_new(vid_free,:) = x1 + ((x2 - x1)*e')*e;
                                X_isfixed(vid_free) = 1;
                                isFree = false;
                            end
                        end
                    end
                end
            end
            
            if isFree
                X_isfixed(vid_free) = 1;
                % this ridge edge won't affect the outline edges
                ridgeEdge_types(reid_curr) = 1;
            end
            
        end
    else % disconnected ridge edge
        X_isfixed(find(X_isfixed == 0, 1)) = 1;
    end
    if isempty(find(X_isfixed == 0, 1))
        break;
    end
    count = count + 1;
end
obj_new = obj;
obj_new.V = X_new;

end