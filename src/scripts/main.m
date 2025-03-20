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
% ElifOzge subjects 
% Loading the behavioral table
%T = readtable([datadir '\raw\response.csv']);
T = readtable([datadir '/raw/response.csv']);
S = readtable([datadir 'raw/subjects_list.csv'], 'Delimiter', ',');

% Aslihan Subjects 
T_A = readtable([datadir '/raw/aslihanyanit.csv']);
subjects_aslihan = [2,42,57,58,64,73,77,78,79,80,81,82,83,...
    84,85,86,87,88,89,90,91,93,94,96,97,99,100,101,103,104,105];

filtered_T = T_A(ismember(T_A.denekId, subjects_aslihan), :);
filtered_T.denekId = strcat("100", string(filtered_T.denekId));  % Convert IDs to string and add "100"
filtered_T.denekId= str2double(filtered_T.denekId);% Convert back to number 

% Saving that table to use in R for later behavioral results
writetable(filtered_T,[datadir '/processed/aslihan_filtered.csv'])

T = vertcat(T,filtered_T); % Merging the two data
T(:,1) = []; % Removes first column that is unneeded id

% All Subjects that we have as the ID of the task but for convinence 
% we will use the subject table. ELIF OZGE SUBEJCTS
% subjects = [8,15,16,18,20,21,24,27,28,29,30,33,35,43,45,51,...
%     59,60,63,64,67,68,69,74,76,77,78,80,82,85,87,88,90,...
%     91,92,93,94,97,99,101,102,104,105,108,109,117,119,...
%     120,121,124,126,132,134,135];

subjects = S.task_id;
subjects = vertcat(subjects,unique(filtered_T.denekId));

ansStruct = arrayfun(@(s) setfield(income_pred(T, s), 'subjectID', s), subjects);
save(fullfile( datapath2 ,'income_pred.mat'),'ansStruct');

pe_array = arrayfun(@(x) calculatePE(x), ansStruct, 'UniformOutput', false);

normalized_pe_array = cellfun(@(x) normalization(x),pe_array,'UniformOutput',false);

spm_pe = cellfun(@(x) spm_pe_regressor(x),normalized_pe_array,'UniformOutput',false);

% Dividing pe to session in task 
% 167. Start of ses-2 
% 333. Start of ses-3
pe_1 = cellfun(@(x) setZeroExcept(x, 1:166), spm_pe, 'UniformOutput', false);
pe_2 = cellfun(@(x) setZeroExcept(x, 167:332), spm_pe, 'UniformOutput', false);
pe_3 = cellfun(@(x) setZeroExcept(x, 333:498), spm_pe, 'UniformOutput', false);

%% Saving pe as regressor for SPM
for i = 1:numel(spm_pe)
    % Extract the numeric data from the i-th cell
    data = spm_pe{i};  % data is 498x1 double
    data1 = pe_1{i};  % data is 498x1 double
    data2 = pe_2{i};  % data is 498x1 double
    data3 = pe_3{i};  % data is 498x1 double

    % Create a filename. For instance: 'Cell1.txt', 'Cell2.txt', ...
    filename1 = sprintf(['/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/data/data_organized/' S.name{i} '/functional/task/pe_all.txt']);
    filename2 = sprintf(['/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/data/data_organized/' S.name{i} '/functional/task/pe_1.txt']);
    filename3 = sprintf(['/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/data/data_organized/' S.name{i} '/functional/task/pe_2.txt']);
    filename4 = sprintf(['/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/data/data_organized/' S.name{i} '/functional/task/pe_3.txt']);
    % Write to a .txt file
    writematrix(data, filename1); writematrix(data1, filename2); writematrix(data2, filename3); writematrix(data3, filename4);
end
%% Saving PE arrays for comparison and compare in R 
group = vertcat(S.group,zeros(31,1)) ;
% Extract second column and convert to matrix
merged_matrix = cell2mat(cellfun(@(x) x(:,1)', pe_array, 'UniformOutput', false));
merged_matrix = [merged_matrix, group];
save('./data/processed/pe_array2.mat', 'merged_matrix');

merged_matrix = cell2mat(cellfun(@(x) x(:,2)', normalized_pe_array, 'UniformOutput', false));
merged_matrix = [merged_matrix, group];
save('./data/processed/normalized_pe_array.mat', 'merged_matrix');

%%
% Apply HGF to all subjects and add subject IDs
hgfStruct = arrayfun(@(s) setfield(hgf_apply_binary(T, s, false), 'subjectID', s), subjects);
save(fullfile(datapath2, 'hgf_struct.mat'), 'hgfStruct');

rwStruct = arrayfun(@(s) setfield(rw_apply_binary(T, s, false), 'subjectID', s), subjects);
save(fullfile(datapath2, 'rw_struct.mat'), 'hgfStruct');

% Define trajectory fields to extract and corresponding filenames
traj_fields = {'epsi', 'epsi', 'wt', 'wt', 'mu', 'mu'};
columns = [2, 3, 2, 3, 2, 3];  % Column index for each field
filenames = {'x2_pe_array.mat', 'x3_pe_array.mat', 'alfa2_array.mat', ...
             'alfa3_array.mat', 'x2_array.mat', 'x3_array.mat'};

% Number of subjects and trials
nsubj = numel(hgfStruct);  % Number of subjects
ndata = size(hgfStruct(1).traj.epsi, 1);  % Number of trials per subject

% Loop over the different data types (x2 PE, x3 PE, alpha2, alpha3, x2, x3)
for i = 1:length(traj_fields)
    % Extract the specific trajectory field and column
    merged_matrix = cellfun(@(x) x(:, columns(i))', ... % Transpose to make trials columns
               arrayfun(@(x) x.traj.(traj_fields{i}), hgfStruct, 'UniformOutput', false), ...
               'UniformOutput', false);

    merged_matrix = cell2mat(merged_matrix);

    % Append group information
    merged_matrix = [merged_matrix, group];

    % Save the processed data
    save(fullfile('./data/processed/', filenames{i}), 'merged_matrix');
end

% RW model PE
traj_fields = {'da'};
columns = 1;  % Column index for each field
filenames = {'rw_pe.mat'};

% Number of subjects and trials
nsubj = numel(hgfStruct);  % Number of subjects
ndata = size(hgfStruct(1).traj.epsi, 1);  % Number of trials per subject

% Loop over the different data types (x2 PE, x3 PE, alpha2, alpha3, x2, x3)
for i = 1:length(traj_fields)
    % Extract the specific trajectory field and column
    merged_matrix = cellfun(@(x) x(:, columns(i))', ... % Transpose to make trials columns
               arrayfun(@(x) x.traj.(traj_fields{i}), rwStruct, 'UniformOutput', false), ...
               'UniformOutput', false);

    merged_matrix = cell2mat(merged_matrix);

    % Append group information
    merged_matrix = [merged_matrix, group];

    % Save the processed data
    save(fullfile('./data/processed/', filenames{i}), 'merged_matrix');
end

%%
% Model evidences for either HGF or RW
lme_hgf = arrayfun(@(x) x.optim.LME, hgfStruct);
lme_rw = arrayfun(@(x) x.optim.LME, rwStruct);

% Group labels (1 = SZ, 0 = HC)
group_labels = group;  % Assuming subjects.group exists

% Extract LMEs for each group
lme_hgf_sz = lme_hgf(group_labels == 1);  
lme_rw_sz  = lme_rw(group_labels == 1);  
lme_hgf_hc = lme_hgf(group_labels == 0);  
lme_rw_hc  = lme_rw(group_labels == 0);  

% Combine into matrices for Bayesian Model Selection
lme_matrix_sz = vertcat(lme_hgf_sz',lme_rw_sz');  % Rows: models, Columns: SZ subjects
lme_matrix_hc = vertcat(lme_hgf_hc', lme_rw_hc');  % Rows: models, Columns: HC subjects

% Run BMS for SZ group
[alpha_sz, exp_r_sz, xp_sz, pxp_sz, bor_sz] = spm_BMS(lme_matrix_sz);

% Run BMS for HC group
[alpha_hc, exp_r_hc, xp_hc, pxp_hc, bor_hc] = spm_BMS(lme_matrix_hc);

% Model evidences suggest that (both xp and bor) there is no favorouble 
% model for both group. Meaning in group level we do not have enough
% evidence to choose one another
%%
% Assuming 'hgf_results' contains the output from TAPAS HGF
load(fullfile(datapath2, 'hgf_struct.mat'))
subject_id = 10;  % Choose a subject to visualize
pe_2 = hgfStruct(subject_id).traj.epsi(:,2);  % Second-level PE
pe_3 = hgfStruct(subject_id).traj.epsi(:,3);  % Third-level PE

q1_1 = prctile(pe_2,20); q2_1 = prctile(pe_2,50); q3_1 = prctile(pe_2,80);
q1_2 = prctile(pe_3,20); q2_2 = prctile(pe_3,50); q3_2 = prctile(pe_3,80);

% Plot PEs over trials
figure;
subplot(2,1,1);
plot(pe_2, 'r', 'LineWidth', 2);
hold on
yline(q1_1,'--b')
yline(q2_1,'--b')
yline(q3_1,'--b')
xlabel('Trial');
ylabel('PE (Level 2)');
title('Second-Level PE Trajectory');
grid on;

subplot(2,1,2);
plot(pe_3, 'b', 'LineWidth', 2);
hold on 
yline(q1_2,'--b')
yline(q2_2,'--b')
yline(q3_2,'--b')
xlabel('Trial');
ylabel('PE (Level 3)');
title('Third-Level PE Trajectory');
grid on;

p2_mat = load('./data/processed/x2_pe_array.mat');

% Get number of subjects and trials
[num_subjects, num_trials] = size(p2_mat.merged_matrix(:, 1:60));

% Compute percentiles across all trials for each subject
q1_all = prctile(p2_mat.merged_matrix(:, 1:60), 20, 2); % 20th percentile (negative PE)
q3_all = prctile(p2_mat.merged_matrix(:, 1:60), 80, 2); % 80th percentile (positive PE)

% Create logical matrices for positive and negative PEs
pos_pe = p2_mat.merged_matrix(:, 1:60) > q3_all; % Positive PEs
neg_pe = p2_mat.merged_matrix(:, 1:60) < q1_all; % Negative PEs

pos_pe = [pos_pe, S.group]; neg_pe = [neg_pe, S.group]; 
save('./data/processed/p2_pe_discrete.mat', 'pos_pe','neg_pe');

% Upper Level
p3_mat = load('./data/processed/x3_pe_array.mat');

% Get number of subjects and trials
[num_subjects, num_trials] = size(p3_mat.merged_matrix(:, 1:60));

% Compute percentiles across all trials for each subject
q1_all = prctile(p3_mat.merged_matrix(:, 1:60), 20, 2); % 20th percentile (negative PE)
q3_all = prctile(p3_mat.merged_matrix(:, 1:60), 80, 2); % 80th percentile (positive PE)

% Create logical matrices for positive and negative PEs
pos_pe = p3_mat.merged_matrix(:, 1:60) > q3_all; % Positive PEs
neg_pe = p3_mat.merged_matrix(:, 1:60) < q1_all; % Negative PEs

pos_pe = [pos_pe, S.group]; neg_pe = [neg_pe, S.group]; 
save('./data/processed/p3_pe_discrete.mat', 'pos_pe','neg_pe');