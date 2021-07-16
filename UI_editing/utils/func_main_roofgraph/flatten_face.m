function X_new = flatten_face(X, flag)

if size(X,1) ~= length(flag)
    error('Inconsistent dimension')
end
if length(find(flag == 1)) < 3
    error('Not enough number of fixed vertices')
end

% if ~is_face_planar(X(flag==1,:))
%     error('Fixed vertices do not form a planar face')
% end

% compute the normal of the plane
Y = X(flag == 1, :);
n = compute_polygon_face_normal(Y);

if isempty(n)
    x1 = Y(1,:);
    x2 = Y(2,:);
    x3 = Y(3,:);
    n = cross(x1 - x2, x3 - x2);
    n = n/norm(n);
end

X_new = X;
% flatten the other vertices
for i = 1:size(X, 1)
    if flag(i) == 0
        p = X(i,:);
        options = optimoptions(@fminunc,'Display','none','Algorithm','quasi-newton');
        func = @(y) norm(cross(cross([p(1:2),y] - Y(1,:), [p(1:2),y] - Y(2,:)), n));
        y = fminunc(func, p(3), options);
        X_new(i,3) = y;
    end
end
end