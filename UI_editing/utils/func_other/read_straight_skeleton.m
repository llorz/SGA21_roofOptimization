function [V, F_ind] = read_straight_skeleton(file_name)
F = {};
fid = fopen(file_name,'r');
line = fgetl(fid);
face = [];
while true
    if line == -1
        F{end+1} = face;
        break
    end
    if strcmp(line, 'face:')
        if ~isempty(face)
            F{end+1} = face;
            face = [];
        end
        line = fgetl(fid);
    else
        pts = sscanf(line,'%f, %f\n');
        face = [face; reshape(pts,1,[])];
        line = fgetl(fid);
    end
end
fclose(fid);
%%
V = unique(cell2mat(F'),'rows');
F_ind = cell(length(F),1);
for face_id = 1:length(F)
    face = F{face_id};
    [~, vid] = ismember(face,V,'rows');
    F_ind{face_id} = vid;
end
end