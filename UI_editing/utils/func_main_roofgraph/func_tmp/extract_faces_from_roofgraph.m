function F = extract_faces_from_roofgraph(roofrays, E_roof, E_dual)
% E_roof: edge list in the roof graph
% E_dual: edge list in the dual graph

E_roof = [min(E_roof,[],2), max(E_roof,[],2)];
unique_eids = unique(E_dual(:));
% for each outline edge, find its associated roof rays
associated_rids = arrayfun(@(eid)...
    find(arrayfun(@(ray)ismember(eid, ray.oeid), roofrays)),...
    unique_eids,'uni',0);

F = {};
for eid = 1:length(associated_rids)
    rids = associated_rids{eid};
    % vtxID in this face: un-ordered
    f = unique([roofrays(rids).vid]);
    count = ones(length(f),1);
    % we now order the vtx in f to form a valid polygon
    face = f(1);
    count(1) = 0;
    while true
        if length(face) == length(f)
            break;
        end
        vtx_cand = f(count > 0);
        edge = [repmat(face(end), length(vtx_cand),1), vtx_cand(:)];
        edge = [min(edge,[],2), max(edge,[],2)];
        select_eid = find(ismember(edge, E_roof,'rows'),1);
        select_vid = vtx_cand(select_eid);
        face(end+1) = select_vid;
        count(f == select_vid) = 0;
    end
    F{end+1} = face;
end
end
