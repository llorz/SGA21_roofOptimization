function [X1, X_ini] = construct_3D_roof_planarity_aesthetic(V, F, V_all, roof_height, para, X_ini)
if nargin < 4, roof_height = 100; end
if nargin < 5
    para.lambda1 = 1; para.lambda2 = 1; para.lambda3 = 1;
end


obj = RoofGraph(V_all, F);
eid_medial = obj.eid_ridge(arrayfun(@(eid)obj.return_edge_edit_type(eid), obj.eid_ridge) == 1);
eid_bisector = obj.eid_roof;

vid_bisector_summary = [];
for eid = reshape(eid_bisector, 1, [])
    
    vids = obj.E(eid,:);
    vid_roof = vids(ismember(vids, obj.vid_roof));
    if_save = true;
    
    eids = obj.find_rvtx_neighboring_redges(vid_roof);
    if length(eids) == 1
        if obj.return_edge_edit_type(eids) == 1
            if_save = false;
        end
    end
    
    if if_save
        vid_outline = setdiff(vids, vid_roof);
        
        eids = obj.find_ovtx_neighboring_oedges(vid_outline);
        vid1 = setdiff(obj.E(eids(1),:), vid_outline);
        vid2 = setdiff(obj.E(eids(2),:), vid_outline);
        
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
func = @(x) energy_planarity_medialAxis_angleBisector(x, vid_xy, vid_z, X_ini, F,...
    vid_medial_summary, vid_bisector_summary, para);
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

X1 = update_var_vtx_positions(x, vid_xy, vid_z, X_ini);
end