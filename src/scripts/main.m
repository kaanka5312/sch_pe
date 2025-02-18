currentdir = pwd;
datadir = ([currentdir '\data\']);
datadir = ([currentdir '/data/']);

dirlist = dir(datadir);
datapath2 = ([currentdir '\results\models\']);
datapath2 = ([currentdir '/results/models/']);
%datapath3 = ([currentdir '\graphics\']);
addpath([currentdir '\src\functions\'])
addpath([currentdir '/src/functions/'])

% Loading the behavioral table
T = readtable([datadir '\raw\response.csv']);
T = readtable([datadir '/raw/response.csv']);

T(:,1) = []; % Removes first column that is unneeded id
subjects = [8,15,16,18,20,21,24,27,28,29,30,33,35,43,45,51,...
    59,60,63,64,67,68,69,74,76,77,78,80,82,85,87,88,90,...
    91,92,93,94,97,99,101,102,104,105,108,109,117,119,...
    120,121,124,126,132,134,135];

ansStruct = arrayfun(@(s) setfield(income_pred(T, s), 'subjectID', s), subjects);
save(fullfile( datapath2 ,'income_pred.mat'),'ansStruct');

pe_array = arrayfun(@(x) calculatePE(x), ansStruct, 'UniformOutput', false);

normalized_pe_array = cellfun(@(x) normalization(x),pe_array,'UniformOutput',false);
