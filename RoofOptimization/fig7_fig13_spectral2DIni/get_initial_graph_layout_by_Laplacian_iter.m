function [V_all, history] = get_initial_graph_layout_by_Laplacian_iter(V, F, V_all)
num_ovtx = size(V,1);
X = V_all;
% get the connectivity graph from the faces
edges = [];
for fid = 1:length(F)
    face = reshape(F{fid},[],1);
    edges = [edges; face, face([2:length(face),1])];
end
E = unique([min(edges,[],2), max(edges,[],2)],'rows');

A_vtx = full(sparse(E(:,1),E(:,2),ones(size(E,1),1), size(X,1), size(X,1)));
A_vtx = A_vtx + A_vtx';
% compute the graph laplacian
L = diag(sum(A_vtx)) - A_vtx;

x0 = V_all(num_ovtx+1:end,:);
x0 = reshape(x0,[],1);

history.x = [];
history.fval = [];
searchdir = [];


func_lap = @(x) norm([V; reshape(x,[],2)]'*L*[V; reshape(x,[],2)],'fro');
options = optimoptions('fminunc','Display','off','Algorithm','quasi-newton',...
    'OptimalityTolerance',1e-12,...
    'FunctionTolerance',1e-12,...
    'OutputFcn',@outfun);
x = fminunc(func_lap, x0, options);
V_all = [V; reshape(x,[],2)];

    function stop = outfun(x,optimValues,state)
        stop = false;
        
        switch state
            case 'init'
                hold on
            case 'iter'
                % Concatenate current point and objective function
                % value with history. x must be a row vector.
                history.fval = [history.fval; optimValues.fval];
                history.x = [history.x, x];
                % Concatenate current search direction with
                % searchdir.
                searchdir = [searchdir;...
                    optimValues.searchdirection'];
%                 plot(x(1),x(2),'o');
%                 % Label points with iteration number and add title.
%                 % Add .15 to x(1) to separate label from plotted 'o'
%                 text(x(1)+.15,x(2),...
%                     num2str(optimValues.iteration));
%                 title('Sequence of Points Computed by fmincon');
            case 'done'
                hold off
            otherwise
        end
    end
end