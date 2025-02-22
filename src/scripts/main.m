currentdir = pwd;

% Windows 
%datadir = ([currentdir '\data\']);
%dirlist = dir(datadir);
%datapath2 = ([currentdir '\results\models\']);
%addpath([currentdir '\src\functions\'])

%datapath3 = ([currentdir '\graphics\']);

% MacOS
datadir = ([currentdir '/data/']);
datapath2 = ([currentdir '/results/models/']);
addpath([currentdir '/src/functions/'])

% Loading the behavioral table
%T = readtable([datadir '\raw\response.csv']);
T = readtable([datadir '/raw/response.csv']);
S = readtable([datadir 'raw/subjects_list.csv'], 'Delimiter', ',');

T(:,1) = []; % Removes first column that is unneeded id

% All Subjects that we have as the ID of the task but for convinence 
% we will use the subject table
% subjects = [8,15,16,18,20,21,24,27,28,29,30,33,35,43,45,51,...
%     59,60,63,64,67,68,69,74,76,77,78,80,82,85,87,88,90,...
%     91,92,93,94,97,99,101,102,104,105,108,109,117,119,...
%     120,121,124,126,132,134,135];

subjects = S.task_id;
ansStruct = arrayfun(@(s) setfield(income_pred(T, s), 'subjectID', s), subjects);
save(fullfile( datapath2 ,'income_pred.mat'),'ansStruct');

pe_array = arrayfun(@(x) calculatePE(x), ansStruct, 'UniformOutput', false);

normalized_pe_array = cellfun(@(x) normalization(x),pe_array,'UniformOutput',false);

spm_pe = cellfun(@(x) spm_pe_regressor(x),normalized_pe_array,'UniformOutput',false);

% Saving pe as regressor

for i = 1:numel(spm_pe)
    % Extract the numeric data from the i-th cell
    data = spm_pe{i};  % data is 498x1 double

    % Create a filename. For instance: 'Cell1.txt', 'Cell2.txt', ...
    filename = sprintf(['/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/data/data_organized/'...
        S.name{i} ...
        '/functional/task/regressor.txt']);
    % Write to a .txt file
    writematrix(data, filename);
end