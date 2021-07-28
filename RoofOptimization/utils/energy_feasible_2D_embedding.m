function fval = energy_feasible_2D_embedding(x, V_fixed, vid_parallel_summary, vid_intersect_summary)
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


fval = fval1 + fval2;
end