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