function M = construct_building_nagoya(X, F, body_height, multi_outline_contour)
if nargin < 3, body_height = 100; end
% BV: building vertices
% BF: building faces
% BF_labels: building face labels
%% compute the 3D roof
BV = X + [0, 0, body_height];
BF = F;
BF_labels = ones(length(F),1);
%% we add the base face
for kk = 1:length(multi_outline_contour)
    outline_contour = multi_outline_contour{kk};
    
    BV = [BV; [X(outline_contour,1:2),zeros(length(outline_contour),1)]];
    %% add the wall faces
    num = size(X,1);
    for qq = 1:kk-1
        num = num + length(multi_outline_contour{qq});
    end
    for i1 = 1:length(outline_contour)
        j2 = i1 + num;
        if i1 == length(outline_contour)
            i4 = 1;
            j3 = 1+num;
        else
            i4 = i1 + 1;
            j3 = i1 + num + 1;
        end
        
        j1 = outline_contour(i1); j4 = outline_contour(i4);
        
        
        BF{end+1} = [j1; j2; j3; j4];
        BF_labels(end+1) = 2+kk;
    end
end
M.verts = BV;
M.faces = BF;
M.face_labels = BF_labels;
end