function [] = plot_building(X1, F)
X = X1;
for i = 1:length(F)
    face = F{i};
    Y = X(face,:);
    fill3(Y(:,1), Y(:,2), Y(:,3),1,'LineWidth',2); hold on; axis equal;
end
view(30,60);
axis off;
end