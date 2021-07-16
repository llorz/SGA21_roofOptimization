function [] = draw_tikz_graph_eid(save_path, X1, E, vid, eid, faces)
fid = fopen(save_path,'w');
fprintf(fid,'\\definecolor{xdxdff}{rgb}{1,0.3333333333333333,0}\n');
fprintf(fid,'\\definecolor{ffvvqq}{rgb}{0.4,0.8,0}\n');
fprintf(fid,'\\definecolor{wwwwww}{rgb}{0.8,0.8,0.8}\n');
fprintf(fid,'\\definecolor{wwwwwq}{rgb}{0.5,0.5,0.5}\n');
fprintf(fid,'\\resizebox{0.35\\linewidth}{!}{\n');
fprintf(fid,'\\begin{tikzpicture}[line cap=round,line join=round,>=triangle 45,x=1cm,y=1cm]\n');
% fprintf(fid,'\\clip(-8,-8) rectangle (8,8);\n');
fprintf(fid,'\\clip(%f,%f) rectangle (%f,%f);\n',...
    min(X1(:,1))-1, min(X1(:,2))-1,max(X1(:,1))+1, max(X1(:,2))+1);


for i = setdiff(1:size(E,1), eid)
    endpoints = E(i,:);
    x1 = X1(endpoints(1),:);
    x2 = X1(endpoints(2),:);
    fprintf(fid,'\\draw [color=wwwwwq, line width=3pt] (%f,%f)-- (%f,%f);\n',...
        x1(1), x1(2), x2(1), x2(2));
end

for i = reshape(eid,1,[])
    endpoints = E(i,:);
    x1 = X1(endpoints(1),:);
    x2 = X1(endpoints(2),:);
    fprintf(fid,'\\draw [color=wwwwww, line width=3pt] (%f,%f)-- (%f,%f);\n',...
        x1(1), x1(2), x2(1), x2(2));
end


for i = reshape(setdiff(1:size(X1,1),vid),1,[])
    fprintf(fid,'\\draw [draw=none, fill=wwwwwq] (%f,%f) circle (4pt);\n', X1(i,1), X1(i,2));
end

for i = reshape(vid,1,[])
    fprintf(fid,'\\draw [draw=none, fill=xdxdff] (%f,%f) circle (4pt);\n', X1(i,1), X1(i,2));
end

if nargin > 5
for i = 1:length(faces)
    F_pos = X1(faces{i},:);
    fprintf(fid,'\\fill [draw=none, fill=ffvvqq, fill opacity=0.1] ');
    for ii = 1:size(F_pos,1)
        fprintf(fid, '(%f,%f) -- ', F_pos(ii,1), F_pos(ii,2));
    end
    fprintf(fid, 'cycle;\n');
end
end

fprintf(fid, '\\end{tikzpicture}}');
end
