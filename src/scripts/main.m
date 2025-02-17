currentdir = pwd;
datadir = ([currentdir '\data\']);
dirlist = dir(datadir);
datapath2 = ([currentdir '\results\models\']);
%datapath3 = ([currentdir '\graphics\']);
addpath([currentdir '\src\functions\'])

% Loading the behavioral table
T = readtable([datadir '\raw\response.csv']);
T(:,1) = []; % Removes first column that is unneeded id
subj = 15 ;
sonuc = income_pred(T,subj);
save(fullfile( datapath2 ,strcat('sonuc_',num2str(subj),'.mat')), 'sonuc');


PE = calculatePE(datapath2,15);

normalization(PE);