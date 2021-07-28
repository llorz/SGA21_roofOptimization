function [V, A] = fix_learned_outline(V, A, para)
keep_vid = find(sqrt(sum((V - V([2:size(V,1),1],:)).^2,2)) > para.eps_ortho);
V_outline = V(keep_vid,:);
A_tmp = A + A';
while(true)
    flag = true;
    num = size(V_outline,1);
    vtxRefID = repmat(1:num, 1,2);
    for i = 1:size(V_outline,1)
        i_prev = vtxRefID(i+num-1);
        i_next = vtxRefID(i+1);
        x_curr = V_outline(i,:);
        x_prev = V_outline(i_prev, :);
        x_next = V_outline(i_next, :);
        e1 = x_prev - x_curr;
        e2 = x_next - x_curr;
        e1 = e1/norm(e1); e2 = e2/norm(e2);
        if 1 - abs(e1*e2') < para.eps_ortho
            V_outline(i,:) = [];
            A_tmp(i_next,:) = A_tmp(i_next,:) + A_tmp(i,:);
            A_tmp(i_prev,:) = A_tmp(i_prev,:) + A_tmp(i,:);
            A_tmp = A_tmp + A_tmp';
            A_tmp = A_tmp > 0;
            flag = false;
            break;
        end
    end
    if flag
        break;
    end
end

rm_vid = find(ismember(V,V_outline, 'rows') == 0);
V(rm_vid,:) = [];
A = A_tmp;
A(rm_vid,:) = []; A(:, rm_vid) = [];
end