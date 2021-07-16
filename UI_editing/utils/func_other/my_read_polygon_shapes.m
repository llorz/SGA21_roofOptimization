function M = my_read_polygon_shapes(dt_dir, file_name)
tmp_name = strsplit(file_name, '.');
file_name = [tmp_name{1}, '.polyshape'];

fid = fopen([dt_dir, file_name]);
tmp = split(fgetl(fid), ': ');
nv = str2double(tmp{2});

tmp = split(fgetl(fid), ': ');
nf = str2double(tmp{2});


verts = zeros(nv, 3);
faces = cell(nf,1);
face_labels = zeros(nf,1);


for i = 1:nv
    line = fgetl(fid);
    verts(i,:) = sscanf(line, '%f,%f,%f\n');
end

for i = 1:nf
    line = fgetl(fid);
    tmp = str2num(line);
    faces{i} = tmp(1:end-1);
    face_labels(i) = tmp(end);
end
fclose(fid);

M = struct();
M.verts = verts;
M.faces = faces;
M.face_labels = face_labels;
M.name = tmp_name{1};

end