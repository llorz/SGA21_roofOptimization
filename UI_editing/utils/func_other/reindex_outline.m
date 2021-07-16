function [X, A_new] = reindex_outline(V, A)
outline_contour = 1:size(V,1);
vids = find(V(:,1) == min(V(:,1)));
[~,id] = min(V(vids,2));
vid_curr = vids(id);
num = size(V,1);
vtxRefId = repmat(1:num,1,2);
vid_prev = vtxRefId(vid_curr + num-1);
vid_next = vtxRefId(vid_curr+1);
normv = @(x) x/norm(x);
e1 = normv(V(vid_prev,:) - V(vid_curr,:));
e2 = normv(V(vid_next,:) - V(vid_curr,:));

if find_rotation(e1,e2) < pi
    % already clockwise
    X = V;
    if nargin > 1 && nargout >1
        A_new = A;
    end
else
    % counter clockwise
    % we reverse the order of the outline contour to make it clockwise
    outline_contour = [1, outline_contour(end:-1:2)];
    X = V(outline_contour,:);
    if nargin > 1 && nargout >1
        [ii, jj] = ind2sub(size(A), find(A));
        face_pairs = [ii, jj];
        tmp = 1+size(V,1) - face_pairs;
        A_new = sparse(tmp(:,1), tmp(:,2), ones(size(tmp,1),1), size(V,1), size(V,1));
        A_new = full(A_new);
    end
end
end