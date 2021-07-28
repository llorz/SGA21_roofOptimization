function [X1, X_ini] = construct_3D_roof_local(V_all, F, vid_x, vid_y, vid_z, var_z, lambda, X_ini,fid)
if nargin < 9
 fid  = [];
end
% initial position
x0 = [X_ini(vid_x,1); X_ini(vid_y, 2);  X_ini(vid_z,3)];
func = @(x) energy_roof_graph(x, vid_x, vid_y, vid_z, var_z, X_ini, F, V_all, lambda, fid);
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12,...
    'MaxFunctionEvaluations',1e4);
x = fminunc(func, x0, options);

X1 = update_var_vtx_positions(x, vid_x, vid_y, vid_z, X_ini);
energy_smallest_eigenval(X1, F)
end


% vid_xy: the vtxIDs where their x,y positions are allowed to change
% vid_z: the vtxIDs where only their z position can be changed
function fval = energy_roof_graph(x, vid_x, vid_y, vid_z, var_z, X_ini, F, X_input, lambda, fid)
X = update_var_vtx_positions(x, vid_x, vid_y, vid_z, X_ini);
fval1 = energy_smallest_eigenval(X, F, fid);
fval2 = norm(X(:,1:2) - X_input(:,1:2),'fro');
if isempty(var_z)
    fval = fval1 + lambda*fval2;
else
    if iscell(var_z)
        fval = fval1 + lambda*fval2;
        for ii = 1:length(var_z)
            fval = fval + var(X(var_z{ii},3));
        end
    else
        fval = fval1 + lambda*fval2 + var(X(var_z,3));
    end
end
end

function fval = energy_smallest_eigenval(X, F, ignore_fid)
if nargin < 3
 ignore_fid = [];   
end
fval = 0;
for fid = setdiff(1:length(F), ignore_fid)
    face = F{fid};
    verts = X(face,:);
    A = cov(verts);
    [~, Sigma, ~] = eig(A);
    fval = fval + Sigma(1);
end

end

function X = update_var_vtx_positions(x, vid_x, vid_y, vid_z, X_ini)
X = X_ini;
num1 = length(vid_x);
num2 = length(vid_y);
X(vid_x,1) = x(1:num1);
X(vid_y,2) = x(num1+1:num1+num2);
X(vid_z,3) = x(num1+num2+1:end);
end