function [X1, X_ini] = construct_3D_roof_temple(V_all, F, vid_xy, vid_z, vid_z_var, lambda, X_ini)

% initial position
x0 = [reshape(X_ini(vid_xy,1:2),[],1); X_ini(vid_z,3)];
func = @(x) energy_roof_graph(x, vid_xy, vid_z, vid_z_var, X_ini, F, V_all, lambda);
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
function fval = energy_roof_graph(x, vid_xy, vid_z, vid_z_var, X_ini, F, X_input, lambda)
X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
fval1 = energy_smallest_eigenval(X, F);
fval2 = norm(X(:,1:2) - X_input(:,1:2),'fro');

fval = fval1 + lambda*fval2;
for ii = 1:length(vid_z_var)
    fval = fval+ var(X(vid_z_var{ii},3));
end
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