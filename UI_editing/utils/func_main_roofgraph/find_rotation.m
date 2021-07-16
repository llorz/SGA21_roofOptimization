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