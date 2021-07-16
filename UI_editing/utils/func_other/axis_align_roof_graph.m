% transform the manually labelled outline that is consistent with input
% image to be axis-aligned
function [obj,R] = axis_align_roof_graph(obj)
X = obj.V(obj.outline_contour,:);
num = size(X,1);
ind_ref = repmat(1:num,1,3);
err_ortho = zeros(num,1); % check the orthogonality error of each outline vertex

for i = 1:num
    k1 = ind_ref(i+num);
    k2 = ind_ref(i+num-1);
    k3 = ind_ref(i+num+1);
    x = X(k1,:);
    x_prev = X(k2,:);
    x_next = X(k3,:);
    e1 = x_next - x;
    e2_tmp = x_prev - x;
    e1 = e1/norm(e1); e2_tmp = e2_tmp/norm(e2_tmp);
    err_ortho(i) = abs(e1*e2_tmp');
end
% the vertex that forms the most orthogonal corner
% use this vertex to align the outline
[~, select_vid] = min(err_ortho);
k1 = ind_ref(select_vid + num);
k2 = ind_ref(select_vid + num - 1);
k3 = ind_ref(select_vid + num + 1);
x = X(k1,:);
x_prev = X(k2,:);
x_next = X(k3,:);
e1 = x_next - x;
e2_tmp = x_prev - x;
e1 = e1/norm(e1); e2_tmp = e2_tmp/norm(e2_tmp);
e2 = e2_tmp - (e1*e2_tmp')*e1;
e2 = e2/norm(e2);

% transformation matrix
R = [e1; e2]';
obj.V = obj.V*R;
end
