function [alpha] = calculateAlpha(sonuc)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
display(['Working on: sonuc_', num2str(sonuc.subjectID) ]);

alpha = [];

alpha = vertcat (sonuc.set1alpha,sonuc.set2alpha,sonuc.set3alpha);

end