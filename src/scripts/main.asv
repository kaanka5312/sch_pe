currentdir = pwd;
datadir = ([currentdir '\data\']);
dirlist = dir(datadir);
datapath2 = ([currentdir '\results\']);
%datapath3 = ([currentdir '\graphics\']);

% Loading the behavioral table
T = readtable([datadir '\raw\response.csv']);
T(:,1) = []; % Removes first column that is unneeded id

sonuc = income_pred(T,15);

