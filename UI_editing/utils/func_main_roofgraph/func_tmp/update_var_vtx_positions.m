function X = update_var_vtx_positions(x, vid_xy, vid_z, X_ini)
X = X_ini;
num = length(vid_xy)*2;
X(vid_xy,1:2) = reshape(x(1:num),length(vid_xy),2);
X(vid_z,3) = x(num+1:end);

end