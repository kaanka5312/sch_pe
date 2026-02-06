function [PEnor] = normalization(PE)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

PEnor = zeros(size(PE,1), size(PE,2));

for i = 1 : size(PE,2)

    %to normalize in [a,b]
    % x = [b-a]*((x-minx)/(maxx-minx)) +a
	maxPE = max(PE(:,i));
	minPE = min(PE(:,i));

	x = 2*(PE(:,i)-minPE)/(maxPE-minPE)-1;

	PEnor(:,i) = x;

end

end
