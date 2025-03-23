function [new_arr] = spm_pe_regressor(pe_array,index,frame)

PEnor = pe_array(:,index);

game =zeros(60,8); %oyun matrisi olustur, her bir kolon bir ekran, decision ve jitter-fixatition icin 2ser ekran toplam 8
game (:, frame) = PEnor; %normalize edilmis degerleri response kolonuna yerle?tir

B = game'; %converts matrix to an array 480x1
B = B(:)'; %index yerlerinde PE degerleri olacak, geri kalanlar? 0
B= B';
arr=B;

% Parameterss
k = 3;                % Length of question slices
ques = zeros(k,1);    % Column vector of zeros to be inserted
loc_index = [81,164,247,330,413,496]; % 1-based indices for insertion

% Compute new array length
new_length = length(arr) + length(loc_index)*k;
new_arr = zeros(new_length,1); % Initialize new array

% Tracking variables
%insert_offset = 0;

new_arr_index = 1;

for i = 1:length(loc_index)
    % Number of elements to copy from arr before this insert
    ncopy = 80;
    
    % Copy arr(prev_index : loc_index(i)-1) into new_arr
    if ncopy > 0
        new_arr(new_arr_index : new_arr_index + ncopy - 1) = ...
            arr((80*(i-1)+1) : 80*i);
        new_arr_index = new_arr_index + ncopy;
    end
    
    % Insert ques into new_arr
    new_arr(new_arr_index : new_arr_index + k - 1) = ques;
    new_arr_index = new_arr_index + k;
end

end