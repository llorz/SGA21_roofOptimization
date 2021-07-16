function [X1, X_ini] = construct_3D_roof_by_optimizing_planarity(V, F, V_all, roof_height, X_ini)
if nargin < 4, roof_height = 100; end
num_ovtx = size(V,1); % # outline vertices
% construct initial 3D roof
if nargin < 5
    X_ini = [V_all, zeros(size(V_all, 1),1)];
    X_ini(num_ovtx+1:end,3) = roof_height; % set the roof vtx with given height
end
% set up the variables for optimization
% for these vtx, we can change the xy positions
vid_xy = (num_ovtx+1):size(X_ini,1);
% for these vtx, we can change the z positions
% note that, we need to fix the z-value of a roof vertex(here
% num_ovtx+1)-th vertex has a fixed height, to avoid degenerated solution
% i.e., all the vtx has 0 z-values, the planarity will be satisfied then
vid_z = (num_ovtx+2):size(X_ini,1);

% initial position
x0 = [reshape(X_ini(vid_xy,1:2),[],1); X_ini(vid_z,3)];
func = @(x) energy_smallest_eigenval_subset(x, vid_xy, vid_z,X_ini, F);
options = optimoptions('fminunc','Display','iter','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);


X1 = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
end