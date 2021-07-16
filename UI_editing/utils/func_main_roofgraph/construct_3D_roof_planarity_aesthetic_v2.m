function [X1, X_ini] = construct_3D_roof_planarity_aesthetic_v2(V, F, V_all, roof_height, para, X_ini)
if nargin < 4, roof_height = 100; end
if nargin < 5
    para.lambda1 = 1; para.lambda2 = 1; para.lambda3 = 1;
end


obj = RoofGraph(V_all, F);
eid_medial = obj.eid_ridge(arrayfun(@(eid)obj.return_edge_edit_type(eid), obj.eid_ridge) == 1);
eid_bisector = obj.eid_roof;

vid_bisector_summary = [];
vid_border_summary = [];
for eid = reshape(eid_bisector, 1, [])
    
    vids = obj.E(eid,:);
    vid_roof = vids(ismember(vids, obj.vid_roof));
    
    vid_outline = setdiff(vids, vid_roof);
    eids = obj.find_ovtx_neighboring_oedges(vid_outline);
    vid1 = setdiff(obj.E(eids(1),:), vid_outline);
    vid2 = setdiff(obj.E(eids(2),:), vid_outline);
    
    
    neigh_eids = obj.find_rvtx_neighboring_redges(vid_roof);
    if length(neigh_eids) == 1
        % just add constraint: angle less than 90
        vid_border_summary = [vid_border_summary;[vid_roof, vid_outline, vid1, vid2, obj.compute_edge_length(neigh_eids)]];
    else
        % add constraint: bisector
        vid_bisector_summary = [vid_bisector_summary;[vid_roof, vid_outline, vid1, vid2]];
    end
end

vid_medial_summary = [];
for eid = reshape(eid_medial, 1, [])
    vids = obj.E(eid,:);
    fids = obj.find_edge_neighboring_faces(eid);
    eid1 = obj.find_outline_edge_in_face(fids(1));
    eid2 = obj.find_outline_edge_in_face(fids(2));
    vid_medial_summary = [ vid_medial_summary;
        [vids(1), obj.E(eid1,:), obj.E(eid2,:)];];
end
%%
num_ovtx = size(V,1); % # outline vertices
% construct initial 3D roof
if nargin < 6
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
tmp = arrayfun(@(vid)length(obj.find_rvtx_neighboring_redges(vid)),obj.vid_roof);
select_id = obj.vid_roof(tmp==max(tmp));
select_id = select_id(1);
vid_z = setdiff((num_ovtx+1):size(X_ini,1), select_id);
% vid_z = (num_ovtx+2):size(X_ini,1);
% initial position
x0 = [reshape(X_ini(vid_xy,1:2),[],1); X_ini(vid_z,3)];
func = @(x) energy_planarity_medialAxis_angleBisector_v2(x, vid_xy, vid_z, X_ini, F,...
    vid_medial_summary, vid_bisector_summary, vid_border_summary, para);
options = optimoptions('fminunc','Display','iter','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

X1 = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
end


% vid_xy: the vtxIDs where their x,y positions are allowed to change
% vid_z: the vtxIDs where only their z position can be changed
function fval = energy_planarity_medialAxis_angleBisector_v2(x, vid_xy, vid_z, X_ini, F,...
    vid_medial_summary, vid_bisector_summary, vid_border_summary, para)
X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
fval1 = energy_smallest_eigenval(X, F);
fval2 = energy_angle_bisector(X, vid_bisector_summary);
fval3 = energy_medial_axis(X, vid_medial_summary);
% fval4 = energy_border(X, vid_border_summary);
if energy_border(X, vid_border_summary) > 0
    fval4 = energy_angle_bisector(X, vid_border_summary);
else
    fval4 = 0;
end
fval = para.lambda1*fval1 + para.lambda2*fval2 + para.lambda3*fval3 + para.lambda4*fval4;
end

function fval = energy_border(X, vid_border_summary)
fval = 0;
for id = 1:size(vid_border_summary,1)
    vids = vid_border_summary(id,:);
    e1 = X(vids(1),:) - X(vids(2),:);
    e2 = X(vids(3),:) - X(vids(2),:);
    e3 = X(vids(4),:) - X(vids(2),:);
    e1 = e1/norm(e1);
    e2 = e2/norm(e2);
    e3 = e3/norm(e3);
    
    if e1*e2' < 0
        fval = fval+1;
    end
    if e1*e3' < 0
        fval = fval +1;
    end
end

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