function obj = optimize_2D_feasible_roofgraph_constrainted(obj, para)
V_ini = obj.V;
num_ovtx = length(obj.vid_outline);
[vid_parallel_summary, vid_intersect_summary] = extract_2D_feasibility_constraint(obj, para);

eid_roof_summary = [];
eid_roof_summary2 = [];
% find the outline bisectors
vtx_rays = split_angle_at_ouline_vertex(obj.V(obj.vid_outline,:));

% for rvid = reshape(obj.vid_roof, 1, [])
%     eids = obj.find_vtx_neighboring_edges(rvid);
%     reids = eids(ismember(eids, obj.eid_roof));
%     if length(reids) == 1
%         vids = obj.E(reids,:);
%         ovid = setdiff(vids, rvid);
%         t = vtx_rays(ovid).direction;
%         eid_roof_summary(end+1,:) = [ovid, rvid, t];
%     elseif length(reids) == 2
%         ovids = setdiff(reshape(obj.E(reids,:),1,[]), rvid);
%         t = vtx_rays(ovids(1)).direction;
%         eid_roof_summary2(end+1,:) = [rvid, ovids, t];
%     elseif length(reids) > 2
%         ovids = setdiff(reshape(obj.E(reids,:),1,[]), rvid);
%         ovid = ovids(2);
%         t = vtx_rays(ovid).direction;
%         eid_roof_summary(end+1,:) = [ovid, rvid, t];
%     end
% end

for rvid = reshape(obj.vid_roof, 1, [])
    eids = obj.find_vtx_neighboring_edges(rvid);
    reids = eids(ismember(eids, obj.eid_roof));
    ovids = setdiff(reshape(obj.E(reids,:),1,[]), rvid);
    if ~isempty(ovids)
        if length(ovids) > 2
            ovid = ovids(2);
        else
            ovid = ovids(1);
        end
        
        t = vtx_rays(ovid).direction;
        eid_roof_summary(end+1,:) = [ovid, rvid, t];
        if length(reids) == 2
            ovids = setdiff(reshape(obj.E(reids,:),1,[]), rvid);
            t = vtx_rays(ovids(1)).direction;
            eid_roof_summary2(end+1,:) = [rvid, ovids, t];
        end
    end
end


V_fixed = V_ini(1:num_ovtx,:);
V_var = V_ini(num_ovtx+1:end,:);

x0 = V_var(:);
func_vad = @(x) energy_feasible_2D_embedding(x, V_fixed, vid_parallel_summary, vid_intersect_summary);
func_angle = @(x) energy_2D_angle_bisector(x, V_fixed, eid_roof_summary, eid_roof_summary2,para);

func = @(x) func_vad(x) + func_angle(x);
options = optimoptions('fminunc','Display','iter','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

V_new = [V_fixed; reshape(x,[],2)];
obj.V = V_new;
end


%%
function fval = energy_2D_angle_bisector(x, V_fixed, eid_roof_summary, eid_roof_summary2, para)
normv = @(x) x/norm(x);
X = [V_fixed; reshape(x,[],2)];

fval = 0;
for cid = 1:size(eid_roof_summary,1)
    vid1 = eid_roof_summary(cid,1);
    vid2 = eid_roof_summary(cid,2);
    e1 = eid_roof_summary(cid,3:4); % the angle bisector direction
    e2 = normv(X(vid1,:) - X(vid2,:));
    fval = fval + (1-abs(e1*e2'));
end

fval1 = fval;

fval = 0;
for cid = 1:size(eid_roof_summary2,1)
    vid1 = eid_roof_summary2(cid,1);
    vid2 = eid_roof_summary2(cid,2);
    vid3 = eid_roof_summary2(cid,3);
    
    len1 = norm(X(vid1,:) - X(vid2,:));
    len2 = norm(X(vid1,:) - X(vid3,:));
    
    e1 = normv(X(vid1,:) - X(vid2,:));
    e2 = eid_roof_summary2(cid,4:5);
    
    fval = fval + ((len1 - len2)/len1)^2 + (1 - abs(e1*e2'));
end
fval2 = fval;

fval = para.w_bisector*fval1 + para.w_equal*fval2;

end