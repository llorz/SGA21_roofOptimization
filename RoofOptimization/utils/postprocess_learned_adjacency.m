function A_new = postprocess_learned_adjacency(V,A)
[ii, jj] = ind2sub(size(A), find(A));
tmp = V;
tmp(end+1,:) = tmp(1,:);
center = (tmp(1:end-1,:) + tmp(2:end,:))/2;


keep_id = find(ii < jj);
face_pairs = [ii(keep_id), jj(keep_id)];
[~,id] = sort(face_pairs(:,1));
face_pairs = face_pairs(id,:);

% remove self-intersections
while true
    % check each pair of line segments, to see if there is an intersection
    for i1 = 1:size(face_pairs,1)-1
        for i2 = i1+1:size(face_pairs,1)
            fids1 = face_pairs(i1,:);
            fids2 = face_pairs(i2,:);
            if length(unique([fids1, fids2])) == 4
                x1 = center(fids1(1),:);
                x2 = center(fids1(2),:);
                x3 = center(fids2(1),:);
                x4 = center(fids2(2),:);
                flag = find_intersection_of_two_line_segments(x1, x2, x3, x4);
                if flag == 1
                    % two line segment intersect with each other
                    if norm(x1-x2) < norm(x3-x4)
                        face_pairs(i2,:) = [];
                    else
                        face_pairs(i1,:) = [];
                    end
                    break; % we start again
                end
            end
            
        end
    end
    
    if i1 == size(face_pairs,1)-1 && i2 == size(face_pairs,1)
        break;
    end
    
end
%%
num_vtx = size(V,1);
while true
    for i_curr = 1:num_vtx
        flag = true;
        if i_curr == 1
            i_prev = num_vtx;
        else
            i_prev = i_curr-1;
        end
        
        if i_curr == num_vtx
            i_next = 1;
        else
            i_next = i_curr + 1;
        end
        
        pids = find(sum(ismember(face_pairs, i_curr),2));
        for pid = reshape(pids, 1, [])
            vid = setdiff(face_pairs(pid), i_curr);
            
            if ~ismember(vid, [i_prev, i_next])
                
                x0 = center(i_curr,:);
                x1 = center(i_prev,:);
                x2 = center(i_next,:);
                x3 = center(vid,:);
                % check if x0-x3 is inbetween x0-x1 and x0-x2
                normv = @(x) x/norm(x);
                e1 = normv(x1 - x0);
                e2 = normv(x2 - x0);
                e3 = normv(x3 - x0);
                theta12 = find_rotation(e1, e2);
                theta13 = find_rotation(e1, e3);
                if theta13 < theta12
                    % this is valid
                else
                    % we need to remove x3
                    face_pairs(pid,:) = [];
                    flag = false;
                    break;
                end
            end
        end
        if ~flag
            break
        end
    end
    if flag
        break;
    end
end
%%
tmp = face_pairs;
A_new = sparse(tmp(:,1), tmp(:,2), ones(size(tmp,1),1), size(V,1), size(V,1));
A_new = full(A_new);

end

function theta = find_rotation(e1, e2)
% We would like to sovle theta from R(theta)*e1 = e2
% where R(theta) is the 2D rotation matrix, we then have
% say e1 = (x1, y1), e2 = (x2, y2);
% cos_t x1 - sin_t y1 = x2
% sin_t x1 + cos_t y1 = y2

A = [e1(1), -e1(2); e1(2), e1(1)];
tmp = e2'\A;

func = @(theta) (cos(theta) - tmp(1))^2 + (sin(theta) - tmp(2))^2;
options = optimoptions(@fminunc,'Display','off');
theta = fminunc(func, pi, options);
theta = wrapTo2Pi(theta);
end