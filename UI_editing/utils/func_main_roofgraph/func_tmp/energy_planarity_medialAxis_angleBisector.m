% vid_xy: the vtxIDs where their x,y positions are allowed to change
% vid_z: the vtxIDs where only their z position can be changed
function fval = energy_planarity_medialAxis_angleBisector(x, vid_xy, vid_z, X_ini, F,...
    vid_medial_summary, vid_bisector_summary, para)
X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
fval1 = energy_smallest_eigenval(X, F);
fval2 = energy_angle_bisector(X, vid_bisector_summary);
fval3 = energy_medial_axis(X, vid_medial_summary);

fval = para.lambda1*fval1 + para.lambda2*fval2 + para.lambda3*fval3;
end

function fval = energy_angle_bisector(X, vid_bisector_summary)
fval = 0;
for id = 1:size(vid_bisector_summary,1)
    vids = vid_bisector_summary(id,:);
    e1 = X(vids(1),:) - X(vids(2),:);
    e2 = X(vids(3),:) - X(vids(2),:);
    e3 = X(vids(4),:) - X(vids(2),:);
    e1 = e1/norm(e1);
    e2 = e2/norm(e2);
    e3 = e3/norm(e3);
    
    fval = fval + (e1*e2' - e1*e3')^2;
end

end


function fval = energy_medial_axis(X, vid_medial_summary)
fval = 0;
for id = 1:size(vid_medial_summary, 1)
vids = vid_medial_summary(id,:);
x1 = X(vids(2),:);
x2 = X(vids(4),:);
e1 = X(vids(3),:) - X(vids(2),:);
e2 = X(vids(5),:) - X(vids(4),:);
e1 = e1/norm(e1);
e2 = e2/norm(e2);

x = X(vids(1),:);
h1 = norm(x-x1 - ((x - x1)*e1')*e1);
h2 = norm(x-x2 - ((x - x2)*e2')*e2);
fval = fval + (h1-h2)^2;
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