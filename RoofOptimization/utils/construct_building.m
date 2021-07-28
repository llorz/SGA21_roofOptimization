function M = construct_building(X, F, body_height)
if nargin < 3, body_height = 100; end


% BV: building vertices
% BF: building faces
% BF_labels: building face labels
%% compute the 3D roof
RG = RoofGraph(X(:,1:2), F);
BV = X + [0, 0, body_height];
BF = F;
BF_labels = ones(length(F),1);
%% we add the base face
outline_contour = RG.outline_contour;

BV = [BV; [X(outline_contour,1:2),zeros(length(outline_contour),1)]];
BF{end+1} = reshape(size(X,1) + (1:length(outline_contour)),[],1);
BF_labels(end+1) = 2;

%% add the wall faces
num = size(X,1);
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
    BF_labels(end+1) = 3;
end

M.verts = BV;
M.faces = BF;
M.face_labels = BF_labels;
end