function X1 = construct_3D_roof_from_straight_skeleton(V_all, F, vid_z_in, roof_height)
if nargin < 4, roof_height = 100; end

X_ini = [V_all, zeros(size(V_all, 1),1)];
X_ini(vid_z_in,3) = roof_height;

vid_xy = [];
% vid_xy = vid_z_in;
vid_z = vid_z_in(2:end);
if isempty(vid_z)
    X1 = X_ini;
    return;
end
% initial position
x0 = [reshape(X_ini(vid_xy,1:2),[],1); X_ini(vid_z,3)];
func = @(x) energy_smallest_eigenval_subset(x, vid_xy, vid_z,X_ini, F);
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

X1 = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
end