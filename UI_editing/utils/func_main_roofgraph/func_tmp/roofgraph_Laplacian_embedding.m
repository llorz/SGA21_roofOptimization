function V_all = roofgraph_Laplacian_embedding(V_ini, E_roof, V)
num_ovtx = size(V,1);
% compute the roof graph adjacency
A_roof = full(sparse(E_roof(:,1),E_roof(:,2),ones(size(E_roof,1),1), size(V_ini,1), size(V_ini,1)));
A_roof = A_roof + A_roof';
% compute the graph laplacian
L = diag(sum(A_roof)) - A_roof;

% update the roof vertex position to minimize the graph Laplacian
x0 = V_ini(num_ovtx+1:end,:);
x0 = reshape(x0,[],1);
func_lap = @(x) norm([V; reshape(x,[],2)]'*L*[V; reshape(x,[],2)],'fro');
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12);
x = fminunc(func_lap, x0, options);
V_all = [V; reshape(x,[],2)];
end
