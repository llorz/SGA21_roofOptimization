function obj = optimize_2D_feasible_roofgraph_close2ini(obj, para)
if nargin < 2
    para.eps_ortho = 1e-3;
    para.lambda_minEdgeLen = 0;
    para.minEdgeLen = 0.5;
    para.lambda_ini = 1e-12;
end
V_ini = obj.V;
num_ovtx = length(obj.vid_outline);
[vid_parallel_summary, vid_intersect_summary] = extract_2D_feasibility_constraint(obj, para);

V_fixed = V_ini(1:num_ovtx,:);
V_var = V_ini(num_ovtx+1:end,:);

x0 = V_var(:);
func = @(x) energy_feasible_2D_embedding(x, V_fixed, vid_parallel_summary, vid_intersect_summary) + ...
    para.lambda_ini*norm(x-x0);
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

V_new = [V_fixed; reshape(x,[],2)];
obj.V = V_new;
end