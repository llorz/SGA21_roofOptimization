function [flag, x_intersect] = find_intersection_of_two_rays(x1, t1, x2, t2, eps_ortho)
if nargin < 5, eps_ortho = 1e-6; end
if 1 - abs(t1*t2') > eps_ortho % not parallel to each other
    [x_intersect,a, b] = find_intersection_of_two_lines(x1,t1,x2,t2, eps_ortho);
    if a > 0 && b > 0
        flag = true;
    else
        flag = false;
        x_intersect = [];
    end
else % t1 and t2 are parallel to each other
    t = x1 - x2;
    t = t/norm(t);
    if 1 - abs(t*t1') < eps_ortho % t // t1 // t2
        flag = true;
        x_intersect = mean([x1; x2]);
    else
        flag = false;
        x_intersect = [];
    end
end
end