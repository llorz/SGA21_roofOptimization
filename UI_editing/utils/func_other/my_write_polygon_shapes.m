function [] = my_write_polygon_shapes(save_dir, save_name, M)
verts = M.verts;
faces = M.faces;
labels = M.face_labels;

write_dir = [save_dir, save_name, '.polyshape'];
nv = size(verts,1);
nf = length(faces);


fid = fopen(write_dir, 'w');
fprintf(fid, '# Number of verts: %d\n', nv);
fprintf(fid, '# Number of faces: %d\n', nf);
fclose(fid);

dlmwrite(write_dir, verts,'-append','precision',12);
for face_id = 1:nf
    tmp = [reshape(faces{face_id},1,[]), labels(face_id)];
    dlmwrite(write_dir, tmp,'-append');
end
end