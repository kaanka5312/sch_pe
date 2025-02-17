function [PE,set1PE,set2PE,set3PE] = calculatePE(resultpath,subj)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
subj = num2str(subj, '%03d');

load([resultpath 'sonuc_' subj '.mat'])
display(['Working on: sonuc_', subj ]);

set3PE = 0;
set2PE = 0; 
set1PE = 0; 
PE = [];

set1PE = abs(sonuc.set1kazanc - sonuc.set1tahminlenen);
set2PE = abs(sonuc.set2kazanc - sonuc.set3tahminlenen);
set3PE = abs(sonuc.set3kazanc - sonuc.set3tahminlenen);

PE = vertcat (set1PE,set2PE,set3PE);

end