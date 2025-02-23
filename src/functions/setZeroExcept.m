% Function to keep only the selected indices and set the rest to 0
function x_new = setZeroExcept(x, idx)
    x_new = zeros(size(x)); % Initialize with zeros
    x_new(idx, :) = x(idx, :); % Copy values in the specified range
end