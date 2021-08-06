function X1 = construct_3D_roof_from_valid_roof_graph(V_all, F, vid_z_in, roof_height)
if nargin < 4, roof_height = 100; end

X_ini = [V_all, zeros(size(V_all, 1),1)];
X_ini(vid_z_in,3) = roof_height;

vid_xy = [];
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



% vid_xy: the vtxIDs where their x,y positions are allowed to change
% vid_z: the vtxIDs where only their z position can be changed
function fval = energy_smallest_eigenval_subset(x, vid_xy, vid_z, X_ini, F)
X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
fval = energy_smallest_eigenval(X, F);
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

