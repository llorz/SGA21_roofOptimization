function [] = plot_dual_graph(V, A)
tmp = V;
tmp(end+1,:) = tmp(1,:);
plot(tmp(:,1), tmp(:,2), 'LineWidth',2); axis equal; hold on;
for i = 1:size(V,1)
    text(V(i,1), V(i,2), num2str(i));
end

% plot adjacency
tmp = V;
tmp(end+1,:) = tmp(1,:);
center = (tmp(1:end-1,:) + tmp(2:end,:))/2;
for i = 1:size(A,1)-1
    for j = i+1:size(A,1)
        if A(i,j) == 1
            x = center([i,j],:);
            plot(x(:,1), x(:,2),'Color','r', 'LineWidth',2);
        end
    end
end

end