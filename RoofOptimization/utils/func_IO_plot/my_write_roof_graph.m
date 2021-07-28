function [] = my_write_roof_graph(save_dir, file_name, obj, type)
switch lower(type)
    case 'primal'
        dlmwrite([save_dir, file_name, '.verts'], obj.V);
        write_file = [save_dir, file_name, '.faces'];
        if exist(write_file, 'file')==2
            delete(write_file);
        end
        cellfun(@(face) ...
            dlmwrite(write_file,[face(:)', face(1)]-1,'-append'),...
            obj.F);
    case 'dual'
        V_save = obj.V(obj.outline_contour,:);
        adj = construct_face_adj(obj);
        dlmwrite([save_dir, file_name,'.outline'], V_save);
        dlmwrite([save_dir, file_name, '.adjacency'], adj);
    otherwise
        error('Invalid the type: only allow primal or dual.')
end

end


function [adj] = construct_face_adj(obj)
outline_contour = obj.outline_contour;
num = length(outline_contour);
A = zeros(num);

adj = [];
for i = 1:num-1
    eid1 = obj.return_edge_ID([i, i+1]);
    fid1 = obj.find_edge_neighboring_faces(eid1);
    if length(fid1) > 1
        error('Invalid outline edge!');
    end
    for j = i+1:num
        if j == num
            eid2 = obj.return_edge_ID([j, 1]);
        else
            eid2 = obj.return_edge_ID([j, j+1]);
        end
        fid2 = obj.find_edge_neighboring_faces(eid2);
        if length(fid2) > 1
            error('Invalid outline edge!');
        end
        
        if fid1 == fid2 % one face with two outline edges
            A(i, j) = 2;
            A(j, i) = 2;
        else
            if obj.is_two_face_adjacent(fid1, fid2)
                A(i, j) = 1;
                A(j, i) = 1;
                adj = [adj; i, j];
            end
        end
    end
end

end