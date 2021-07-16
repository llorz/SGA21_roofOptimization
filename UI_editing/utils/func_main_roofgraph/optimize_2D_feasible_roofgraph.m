function obj = optimize_2D_feasible_roofgraph(obj, para)
V_ini = obj.V;
num_ovtx = length(obj.vid_outline);
[vid_parallel_summary, vid_intersect_summary] = extract_2D_feasibility_constraint(obj, para);

V_fixed = V_ini(1:num_ovtx,:);
V_var = V_ini(num_ovtx+1:end,:);

x0 = V_var(:);
func = @(x) energy_feasible_2D_embedding(x, V_fixed, vid_parallel_summary, vid_intersect_summary);
options = optimoptions('fminunc','Display','iter','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func, x0, options);

V_new = [V_fixed; reshape(x,[],2)];
obj.V = V_new;
end