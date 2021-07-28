function t = compute_angle_bisector(vtx_prev, vtx_curr, vtx_next)
R = @(theta) [cos(theta) -sin(theta); sin(theta) cos(theta)];
e1 = vtx_prev - vtx_curr;
e2 = vtx_next - vtx_curr;
e1 = e1/norm(e1);
e2 = e2/norm(e2);

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

t = R(theta/2)*e1';
t = t';
end