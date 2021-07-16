function [X1, X_ini] = construct_3D_roof_from_roof_graph(V, F, V_all, roof_height, lambda, vid_fixed, X_ini)
if nargin < 4, roof_height = 100; end
if nargin < 5, lambda = 1; end

num_ovtx = size(V,1); % # outline vertices
if nargin < 7
    % construct initial 3D roof
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
if isempty(vid_fixed)
    vid_z = (num_ovtx+2):size(X_ini,1);
else
    vid_z = setdiff((num_ovtx+1):size(X_ini,1),vid_fixed);
end

% initial position
x0 = [reshape(X_ini(vid_xy,1:2),[],1); X_ini(vid_z,3)];
func = @(x) energy_roof_graph(x, vid_xy, vid_z,X_ini, F, V_all, lambda);
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12,...
    'MaxFunctionEvaluations',1e4);
x = fminunc(func, x0, options);

X1 = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
energy_smallest_eigenval(X1, F)
end


% vid_xy: the vtxIDs where their x,y positions are allowed to change
% vid_z: the vtxIDs where only their z position can be changed
function fval = energy_roof_graph(x, vid_xy, vid_z, X_ini, F, X_input, lambda)
X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
fval1 = energy_smallest_eigenval(X, F);
fval2 = norm(X(:,1:2) - X_input(:,1:2),'fro');

fval = fval1 + lambda*fval2;
end

function fval = energy_smallest_eigenval(X, F)
fval = 0;
for fid = 1:length(F)
    face = F{fid};
    verts = X(face,:);
    A = cov(verts);
    [~, Sigma, ~] = eig(A);
    fval = fval + Sigma(1);
end

end

function X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini)
X = X_ini;
num = length(vid_xy)*2;
X(vid_xy,1:2) = reshape(x(1:num),length(vid_xy),2);
X(vid_z,3) = x(num+1:end);

end