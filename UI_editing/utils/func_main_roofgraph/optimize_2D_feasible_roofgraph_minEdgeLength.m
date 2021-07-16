function obj = optimize_2D_feasible_roofgraph_minEdgeLength(obj, para)
V_ini = obj.V;
num_ovtx = length(obj.vid_outline);
[vid_parallel_summary, vid_intersect_summary] = extract_2D_feasibility_constraint(obj, para);

V_fixed = V_ini(1:num_ovtx,:);
V_var = V_ini(num_ovtx+1:end,:);

x0 = V_var(:);
func = @(x) energy_feasible_2D_embedding_minEdgeLength(x, V_fixed, vid_parallel_summary, vid_intersect_summary, para);
options = optimoptions('fminunc','Display','iter','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

V_new = [V_fixed; reshape(x,[],2)];
obj.V = V_new;
end

function fval = energy_feasible_2D_embedding_minEdgeLength(x, V_fixed, vid_parallel_summary, vid_intersect_summary, para)
normv = @(x) x/norm(x);
X = [V_fixed; reshape(x,[],2)];
%%
fval = 0;
for cid = 1:size(vid_parallel_summary,1)
    vid1 = vid_parallel_summary(cid,1);
    vid2 = vid_parallel_summary(cid,2);
    e1 = vid_parallel_summary(cid,3:4);
    e2 = normv(X(vid1,:) - X(vid2,:));
    fval = fval + (1-abs(e1*e2'));
end
fval1 = fval;


fval = 0;
for cid = 1:size(vid_intersect_summary,1)
    vid1 = vid_intersect_summary(cid,1);
    vid2 = vid_intersect_summary(cid,2);
    x0 = vid_intersect_summary(cid,3:4);
    x1 = X(vid1,:);
    x2 = X(vid2,:);
    
    e1 = normv(x1-x0);
    e2 = normv(x2-x0);
    
    fval = fval + (1-abs(e1*e2'));
end
fval2 = fval;


fval = 0;
for cid = 1:size(vid_parallel_summary,1)
    vid1 = vid_parallel_summary(cid,1);
    vid2 = vid_parallel_summary(cid,2);
    fval = fval + (norm(X(vid1,:) - X(vid2,:)) - para.minEdgeLen)^2;
    
end
fval3 = fval;

fval = fval1 + fval2 + para.lambda_minEdgeLen*fval3;
end