function [flag, x_intersect] = find_intersection_of_two_line_segments(x1, x2, x3, x4)
t1 = (x2 - x1);
t2 = (x4 - x3);

t1 = t1/norm(t1);
t2 = t2/norm(t2);

if 1 - abs(t1*t2') > eps % not parallel to each other
    [x_intersect,a, b] = find_intersection_of_two_lines(x1,t1,x3,t2);
    if isempty(x_intersect)
        flag = false;
    else
        if a > 0 && b > 0 && a < norm(x2-x1) && b < norm(x3-x4)
            flag = true;
        else
            flag = false;
            x_intersect = [];
        end
    end
else
    flag = false;
    x_intersect = [];
end
end