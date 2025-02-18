function [PE,set1PE,set2PE,set3PE] = calculatePE(sonuc)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
display(['Working on: sonuc_', num2str(sonuc.subjectID) ]);

set3PE = 0;
set2PE = 0; 
set1PE = 0; 
PE = [];

set1PE = abs(sonuc.set1kazanc - sonuc.set1tahminlenen);
set2PE = abs(sonuc.set2kazanc - sonuc.set3tahminlenen);
set3PE = abs(sonuc.set3kazanc - sonuc.set3tahminlenen);

PE = vertcat (set1PE,set2PE,set3PE);

end