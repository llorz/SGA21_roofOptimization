classdef RoofGraph
    properties( Constant = true )
        % if two edges forms a degree smaller than eps_degree, we assume
        % these two edges are paralle to each other
        eps_degree = 10;
        
        % the edge length should be larger than
        % median(edge_length)*eps_edgelen
        eps_edgeLength = 1e-2;
        
        eps_ortho = 1e-2;
    end
    
    properties
        IfPlotShowLabel = true;
    end
    
    properties
        V   % vertex set
        E   % edge set
        F   % face set
        nv  % number of vertices
        ne  % number of edges
        nf  % number of faces
        
        
        eid_outline         % outline edges, where the edge is contained in a singe face
        eid_roof            % roof edges that connect one roof vertex and one outline vertex
        eid_ridge           % roof edges that connect two roof vertices
        vid_outline         % outline vertices, the endpoints of the outline edge
        vid_roof            % roof vertex, the variables we solve for
        
        outline_contour     % the ordered ouline vertices that can form a base face
    end
    
    methods
        function obj = RoofGraph(V, F, outline_edges)
            if nargin < 3, outline_edges = []; end
            
            E = extract_edges_from_faces(F);
            [V, E, F] = remove_unreferenced_vtx(V, E, F);
            
            % some of the new outline edges might not be referenced
            E = [E; outline_edges];
            E = remove_duplicated_edges(E);
            
            obj.V = V;
            obj.F = cellfun(@(x)reshape(x,[],1),F,'uni',0);
            obj.E = E;
            
            obj.nv = size(obj.V, 1);
            obj.ne = size(obj.E, 1);
            obj.nf = length(obj.F);
            
            
            obj = classify_outline_roof_edge_and_vtx(obj, outline_edges);
            obj = find_outline_contour(obj);
        end
        
        function obj = update(obj, V, F, outline_edges)
            if nargin < 4, outline_edges = []; end
            obj.V = V;
            obj.F = cellfun(@(x)reshape(x,[],1),F,'uni',0);
            obj.E = extract_edges_from_faces(F);
            
            obj.nv = size(obj.V, 1);
            obj.ne = size(obj.E, 1);
            obj.nf = length(obj.F);
            
            
            obj = classify_outline_roof_edge_and_vtx(obj, outline_edges);
            obj = find_outline_contour(obj);
        end
        % classify the vtx into: outline or roof
        % classify the edge into: outline, roof, ridge
        function obj = classify_outline_roof_edge_and_vtx(obj, outline_edges)
            if isempty(outline_edges)
                % find the outline edges: that is shared by only one face
                tmp_outline_eid = [];
                for eid = 1:size(obj.E,1)
                    if length(obj.find_edge_neighboring_faces(eid)) == 1
                        tmp_outline_eid(end+1) = eid;
                    end
                end
            else
                res = ismember(outline_edges,obj.E,'rows') + ismember(outline_edges(:,[2,1]),obj.E,'rows');
                if isempty(find(res == 0, 1))
                    num = size(outline_edges,1);
                    tmp_outline_eid = zeros(num,1);
                    for ii = 1:num
                        tmp_outline_eid(ii) = obj.return_edge_ID(outline_edges(ii,:));
                    end
                else
                    error('The specified outline edges are not included');
                end
            end
            
            obj.eid_outline = tmp_outline_eid(:);
            
            
            % find the outline vtx: that are endpoints of the outline edges
            tmp_outline_vid = unique(reshape(obj.E(tmp_outline_eid,:),[],1));
            obj.vid_outline = tmp_outline_vid(:);
            
            % roof vtx: the rest of the vertices
            tmp_roof_vid = setdiff(1:obj.nv, tmp_outline_vid);
            obj.vid_roof = tmp_roof_vid(:);
            
            % find the ridge edge: where both endpoints are roof vertex
            tmp_ridge_eid = find(sum(ismember(obj.E,obj.vid_roof),2) == 2);
            obj.eid_ridge = tmp_ridge_eid(:);
            
            % roof edge: one endpoint is outline vertex and the other is
            % ridge edge
            tmp_roof_eid = setdiff(1:obj.ne, [obj.eid_outline; obj.eid_ridge]);
            obj.eid_roof = tmp_roof_eid(:);
        end
        
        
        % find the edgeID if the edge exsits, otherwise return 0
        function eid = return_edge_ID(obj, edge)
            [~, id1] = ismember(edge, obj.E, 'rows');
            [~, id2] = ismember(edge([2,1]), obj.E, 'rows');
            
            eid = id1 + id2;
            % if eid = 0, the edge is not found
            if eid == 0
                %warning('The query edge does not exist in the roof graph');
            end
        end
        
        
        % for an edge, find its neighboring faceID (at most 2)
        function face_id = find_edge_neighboring_faces(obj, eid)
            face_id = [];
            edge = obj.E(eid,:);
            for fid = 1:length(obj.F)
                face = obj.F{fid};
                if is_edge_in_face(edge, face)
                    face_id(end+1) = fid;
                end
            end
        end
        
        
        % compute the direction (normalized) of the query edge
        function e = compute_edge_direction(obj, eid)
            edge = obj.V(obj.E(eid,:),:);
            e = edge(1,:) - edge(2,:);
            e = e/norm(e);
        end
        
        
        % compute the length of the query edge
        function len = compute_edge_length(obj, eid)
            edge = obj.V(obj.E(eid,:),:);
            len = norm(edge(1,:) - edge(2,:));
        end
        
        
        % for a vertex, find its neighboring edgeID
        function edge_id = find_vtx_neighboring_edges(obj, vid)
            edge_id = find(sum(ismember(obj.E, vid),2) == 1);
        end
        
        
        % find the outline edge id in the query face
        function [outline_eids_in_face, eids] = return_outline_edgesID_in_face(obj, fid)
            face = obj.F{fid};
            edge = [face, face([2:length(face),1])];
            edge = [min(edge,[],2), max(edge,[],2)];
            [~, eids] = ismember(edge,obj.E,'rows');
            outline_eids_in_face = eids(ismember(eids, obj.eid_outline) == 1);
        end
        
        % find the ridge edge id in the query face
        function [ridge_eids_in_face, eids] = return_ridge_edgesID_in_face(obj, fid)
            face = obj.F{fid};
            edge = [face, face([2:length(face),1])];
            edge = [min(edge,[],2), max(edge,[],2)];
            [~, eids] = ismember(edge,obj.E,'rows');
            ridge_eids_in_face = eids(ismember(eids, obj.eid_ridge) == 1);
        end
        
        
        % find the roof vertex in the query face
        function [roof_vids_in_face] = return_roof_vtxID_in_face(obj, fid)
            face = obj.F{fid};
            roof_vids_in_face = face(ismember(face, obj.vid_roof));
        end
        
        function [neigh_fids] = find_neighboring_faces_of_input_face(obj, fid)
            neigh_fids = [];
            for check_fid =  setdiff(1:obj.nf, fid)
                if obj.is_two_face_adjacent(fid, check_fid)
                    neigh_fids(end+1) = check_fid;
                end
            end
        end
        
        % check if two faces are adjacent
        function [flag, shared_eid] = is_two_face_adjacent(obj, fid1, fid2)
            face1 = obj.F{fid1};
            face2 = obj.F{fid2};
            edges1 = [face1, face1([2:length(face1),1])];
            edges2 = [face2, face2([2:length(face2),1])];
            eid1 = find(ismember(edges1, edges2,'rows'));
            eid2 = find(ismember(edges1, edges2(:,[2,1]),'rows'));
            eids = [eid1(:); eid2(:)];
            
            if isempty(eids)
                flag = false;
                shared_eid = [];
            else
                flag = true;
                shared_eid  = arrayfun(...
                    @(eid) obj.return_edge_ID(edges1(eid,:)), ...
                    eids);
            end
        end
        
        % check if two edges are adjacent
        function [flag, shared_vid] = is_two_edge_adjacent(obj, eid1, eid2)
            edge1 = obj.E(eid1,:);
            edge2 = obj.E(eid2,:);
            shared_vid = intersect(edge1, edge2);
            if isempty(shared_vid)
                flag = false;
            else
                flag = true;
            end
        end
        
        
        % find the outline edge ID in the query face if exists
        function outline_eid = find_outline_edge_in_face(obj, fid)
            face = reshape(obj.F{fid}, [],1);
            edges = [face, face([2:length(face),1])];
            eid1 = find(ismember(edges, obj.E(obj.eid_outline,:),'rows')==1);
            eid2 = find(ismember(edges(:,[2,1]), obj.E(obj.eid_outline,:),'rows')==1);
            eids = [eid1(:); eid2(:)];
            outline_eid = arrayfun(@(eid) obj.return_edge_ID(edges(eid,:)), eids);
            if isempty(outline_eid) && length(face) > 3
                warning('The query face does not have an outline edge!');
            end
        end
        
        
        % for an outline vertex, find its neighboring outline edgeID
        function edge_id = find_ovtx_neighboring_oedges(obj, vid)
            if ~ismember(vid, obj.vid_outline)
                error('The query vertex is not an outline vertex');
            else
                edge_id = obj.eid_outline(sum(ismember(obj.E(obj.eid_outline,:), vid),2) == 1);
            end
        end
        
        
        % for a ridge vertex, find its neighboring ridge edgeID
        function edge_id = find_rvtx_neighboring_redges(obj, vid)
            if ~ismember(vid, obj.vid_roof)
                error('The query vertex is not a roof vertex');
            else
                edge_id = obj.eid_ridge(sum(ismember(obj.E(obj.eid_ridge,:), vid),2) == 1);
            end
        end
        
        % find the faces that do not contain outline edges
        % its okay to have a triangle face without outline edges
        function fids = find_face_without_outline_edge(obj)
            fids = [];
            for fid = 1:obj.nf
                eids = obj.find_outline_edge_in_face(fid);
                if isempty(eids)
                    face = obj.F{fid};
                    if length(face) > 3
                        fids(end+1) = fid;
                    else
                        if length(find(ismember(face, obj.vid_outline) == 1)) ~= 1
                            fids(end+1) = fid;
                        end
                    end
                end
            end
        end
        
        
        % find the faces that contain multiple outline edges
        function fids = find_face_with_multiple_outline_edge(obj)
            edges_group = category_outline_edges(obj);
            func_groupID = @(eid)find(cellfun(@(x)ismember(eid,x),edges_group));
            
            fids = [];
            for fid = 1:obj.nf
                eids = obj.return_outline_edgesID_in_face(fid);
                if length(eids) > 1
                    % if there are multiple outlines in the face
                    % check if they are parallel to each other
                    % it is okay to have multiple parallel outline edges
%                     gid = arrayfun(@(eid)func_groupID(eid), eids);
%                     if length(unique(gid)) > 1 % outline edges are not parallel
                        fids(end+1) = fid;
%                     end
                end
            end
        end
        
        % check if two edges are adjacent to each other
        function flag = check_if_two_edges_adjacent(obj, eid1, eid2)
            if length(unique([obj.E(eid1,:), obj.E(eid2,:)])) == 3
                flag = true;
            else
                flag = false;
            end
        end
        
        
        % find the outline contour of the roof graph
        function [obj] = find_outline_contour(obj)
            start = obj.vid_outline(1);
            outlineContour = [];
            curr = start;
            while true
                outlineContour(end+1) = curr;
                eids = obj.find_ovtx_neighboring_oedges(curr);
                candidate_next = setdiff(unique(reshape(obj.E(eids,:),[],1)), outlineContour);
                if ~isempty(candidate_next)
                    next = candidate_next(1);
                    curr = next;
                else
                    break
                end
            end
            outlineContour = outlineContour(:);
            if isequal(unique(outlineContour), unique(obj.vid_outline))
                obj.outline_contour = outlineContour;
            else
                warning('Cannot find valid outline contour');
            end
        end
        
        % check if the graph is simple
        % i.e., any ridge edge is connected to faces that are
        % either: a triangle face
        % or a face that contains outline edges
        function [flag, prob_eid] = is_graph_simple(obj)
            prob_eid = [];
            for eid = reshape(obj.eid_ridge, 1, [])
                fids = obj.find_edge_neighboring_faces(eid);
                eid1 = obj.return_outline_edgesID_in_face(fids(1));
                eid2 = obj.return_outline_edgesID_in_face(fids(2));
                
                % check the two faces seperately
                if isempty(eid1)
                    if length(obj.F{fids(1)}) == 3
                        flag1 = true;
                    else
                        flag1 = false;
                    end
                else
                    flag1 = true;
                end
                
                if isempty(eid2)
                    if length(obj.F{fids(2)}) == 3
                        flag2 = true;
                    else
                        flag2 = false;
                    end
                else
                    flag2 = true;
                end
                
                % if both faces are either a triangle or a face with
                % outline edges
                if ~(flag1 && flag2)
                    prob_eid(end+1) = eid;
                end
            end
            if isempty(prob_eid)
                flag = true;
            else
                flag = false;
            end
        end
        
        
        function [ovid_prev, ovid_next] = find_neighboring_outline_vertex(obj, ovid)
            num = length(obj.outline_contour);
            vtxID_ref = repmat(1:num, 1, 3);
            
            [~, i_curr] = ismember(ovid, obj.outline_contour);
            i_prev = vtxID_ref(i_curr + num - 1);
            i_next = vtxID_ref(i_curr + 1);
            
            ovid_prev = obj.outline_contour(i_prev);
            ovid_next = obj.outline_contour(i_next);
            
        end
        
        function [fids] = find_vtx_neighboring_faces(obj, vid)
            fids = unique(cell2mat(arrayfun(@(eid) reshape(obj.find_edge_neighboring_faces(eid),[],1),...
                obj.find_vtx_neighboring_edges(vid),'uni',0)));
        end
        
        function vids = find_vtx_neighboring_vtxs(obj, vid)
            vids = unique(reshape(obj.E(obj.find_vtx_neighboring_edges(vid),:),[],1));
            
            vids = setdiff(vids, vid);
        end
        
        % for a query edge, if type = 
        % 0: this is outline edge, we cannot edit it
        % 1: this edge is parrallel to the outline edges, we cannot change
        % the direction
        % 2: this edge intersects with the outline edges, we cannot change
        % the intersecting point
        % 3: this is roof edge, the roof vertex endpoint can be changed
        % freely
        function type = return_edge_edit_type(obj, eid)
            if ismember(eid, obj.eid_outline)
                type = 0; % outline edge
            elseif ismember(eid, obj.eid_roof)
                type = 3;
            else
                fids = obj.find_edge_neighboring_faces(eid);
                eid1 = obj.find_outline_edge_in_face(fids(1));
                eid2 = obj.find_outline_edge_in_face(fids(2));
                e1 = obj.compute_edge_direction(eid1);
                e2 = obj.compute_edge_direction(eid2);
                if 1 - abs(e1*e2') < obj.eps_ortho
                    type = 1; % parallel to outline edges, the direction cannot be changed
                else
                    type = 2; % intersecting with the outline edges, the point cannot be changed
                end
            end
            
        end
        
        
        function [] = plot(obj)
            color = lines(obj.nf);
            scatter(obj.V(:,1), obj.V(:,2),20,'k','filled'); hold on;
            
            for eid = reshape(obj.eid_outline,1,[])
                edge = obj.V(obj.E(eid,:),:);
                plot(edge(:,1), edge(:,2), 'g-.','Color', 'g','LineWidth',2);
            end
            
            for eid = reshape(obj.eid_ridge,1,[])
                edge = obj.V(obj.E(eid,:),:);
                plot(edge(:,1), edge(:,2), 'r-','Color', 'r', 'LineWidth',2);
            end
            
            for eid = reshape(obj.eid_roof,1,[])
                edge = obj.V(obj.E(eid,:),:);
                plot(edge(:,1), edge(:,2), 'k--', 'LineWidth',2);
            end
            
            for fid = 1:obj.nf
                face = obj.V(obj.F{fid},:);
                fill(face(:,1), face(:,2), color(fid,:),'FaceAlpha',0.1,'EdgeAlpha',0);
            end
            
            
            set(gca,'Fontsize',15,'FontWeight','Bold','LineWidth',2, 'box','on');
            axis equal;
            
            if obj.IfPlotShowLabel
                % add edge labels
                for eid = 1:size(obj.E,1)
                    edge = obj.V(obj.E(eid,:),:);
                    x = mean(edge);
                    text(x(1), x(2),['e',num2str(eid)],'Color','blue');
                end
                
                % add face labels
                for fid = 1:size(obj.F,1)
                    face =  obj.V(obj.F{fid},:);
                    x = mean(face);
                    text(x(1), x(2),['f',num2str(fid)],'Color','red');
                end
                
                % add vertex labels
                for vid = 1:size(obj.V,1)
                    x = obj.V(vid,:);
                    text(x(1), x(2),['v',num2str(vid)],'Color','red');
                end
            end
            hold off;
        end
    end
end




function E = extract_edges_from_faces(F)
edges = [];
for fid = 1:length(F)
    face = reshape(F{fid},[],1);
    edges = [edges; face, face([2:length(face),1])];
end
E = unique([min(edges,[],2), max(edges,[],2)],'rows');
end



function flag = is_edge_in_face(edge, face)
face = face(:);
face_edges = [face, face([2:length(face),1])];
flag = ismember(edge, face_edges,'rows') ||...
    ismember(edge([2,1]), face_edges,'rows');
end



function E_new = remove_duplicated_edges(E)
E_new = unique([min(E,[],2), max(E,[],2)],'rows');
E_new(E_new(:,1) == E_new(:,2),:) = [];
end



function [V, E, F] = remove_unreferenced_vtx(V, E, F)
% there might be some edges that are not used in the faces
% x1 --- x2 --- x3
% e.g., edges(x1, x2) (x2, x3) and (x1, x3) are included in E
% but (x1, x3) is not used in any of the faces
% we should remove it


% F = fix_overlapped_faces(F, V);
E = [E; extract_edges_from_faces(F)];
E = remove_duplicated_edges(E);

if nargin > 2 && nargout > 2
    rm_eid = [];
    for eid = 1:size(E,1)
        edge = E(eid,:);
        flag = false;
        for fid = 1:length(F)
            face = F{fid};
            if is_edge_in_face(edge, face)
                flag = true;
                break;
            end
        end
        if ~flag
            rm_eid(end+1) = eid;
        end
    end
    E(rm_eid,:) = [];
    
    num = cellfun(@(face) length(face), F);
    rm_fids = find(num < 3);
    F(rm_fids) = [];
end

% we them remove the unreferenced vertex
if length(unique(E(:))) ~= size(V,1)
    E = unique([min(E,[],2), max(E,[],2)],'rows');
    rm_vid = setdiff(1:size(V,1), unique(E(:)));
    V(rm_vid,:) = [];
    % udpate edge id
    edge_id = unique(E(:));
    [~, E] = ismember(E, edge_id);
    % update face id
    if nargin > 2 && nargout > 2
        for fid = 1:length(F)
            face = F{fid};
            face(ismember(face, rm_vid)) = [];
            [~, face] = ismember(face, edge_id);
            F{fid} = face;
        end
    end
end
end

function F = fix_overlapped_faces(F_in, V)
nf = length(F_in);
faces = [];
for i = 1:nf
    faces = [faces, polyshape(V(F_in{i},:))];
end

for i = 1:nf-1
    p1 = faces(i);
    for j = i+1:nf
        p2 = faces(j);
        p = intersect(p1, p2);
        if ~isempty(p.Vertices)
            p3 = subtract(p2, p1);
            if ~isempty(p3.Vertices)
                faces(j) = p3;
                p2 = faces(j);
            end
            
            p3 = subtract(p1, p2);
            if ~isempty(p3.Vertices)
                faces(i) = p3;
                p1 = faces(i);
            end
        end
    end
end

F = cell(length(faces),1);
for fid = 1:length(faces)
    F{fid} = knnsearch(V, faces(fid).Vertices);
end

F(cellfun(@(face) length(face), F) == 0) = [];

end


