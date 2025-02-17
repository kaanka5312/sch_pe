function [PEnor] = normalization(PE)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

PEnor = zeros(size(PE,1), size(PE,2));

for i = 1 : size(PE,2)

    %to normalize in [a,b]
    % x = [b-a]*((x-minx)/(maxx-minx)) +a
maxPE = max(PE(:,i));
minPE = min(PE(:,i));

x = 2*(PE(:,1)-minPE)/(maxPE-minPE)-1;

%sinyali kuvvetlendirmek için 1 e böl
%PEnor (:,i) = 1./x;
%otherwise
PEnor(:,i+1) = x;

end

end