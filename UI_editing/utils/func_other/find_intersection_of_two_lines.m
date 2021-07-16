function [x_intersect, a, b] = find_intersection_of_two_lines(x1,t1,x2,t2, eps_ortho)
if nargin < 5, eps_ortho = 1e-6; end
if 1 - abs(t1*t2') < eps_ortho % two lines are parallel to each other
%     warning('Computing intersection between two parallel lines!')
    x_intersect = [];
    a = [];  b = [];
else
    tmp = (x2-x1)/[t1;t2];
    a = tmp(1); b = -tmp(2);
    val = norm((x1 + a*t1) - (x2 + b*t2));
    if val > 1e-9
        error('Invalid intersection')
    end
    x_intersect = x1 + a*t1;
end
end

