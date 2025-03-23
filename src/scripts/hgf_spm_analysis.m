% This is PE analysis with HGF not RW
% 22.03.2025

clear all; clc;

originalpath = pwd;
%datadir = './analysis/firstlevel/';
datadir = './analysis/preprocessing/'; % './first.level/';
datadir2 = './data/data_organized/'; 
f_output = './analysis/firstlevel_HGF/'; % First-level output folder
aslihan_path = '/Volumes/Elements/SoCAT/Aslihan_TrustGame/Kontrol/';
dirlist = dir(datadir2);

S = readtable('/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv', 'Delimiter', ',');
% Preparing Aslihan's data to merge with elifozge
subj = S(52:end,"name");
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

tic
for i= 1:numel(S.name) % Subject's name

    if i == 39 || i==74 %ecemyilmaz 74 has 3 more TR?
        disp('Breaking loop because i == 39');
        continue;  % Stops the loop when i reaches 39
    end
     
    display(['Working on: ' S.name{i} ]);
    
    %%% yeni hastalar icin bu ve alttaki bolumu ac %%%
    
%     %create directory for the new subjetcs
    % data_preprocessing = [datadir S.name{i}];
    % mkdir(data_preprocessing);
    % 
    % disp('Copying the necessary files... ');
    % source = [datadir2 S.name{i}];
    % dest = [datadir S.name{i}];
    % copyfile(source, dest)
    % disp('Completed. Starting the preprocessing..');

    
%     %create the subdirectories --bu part gerekli degil
%     cd([datadir dirlist(i).name]);
%     mkdir('functional')
%     mkdir('functional','rest')
%     mkdir('functional','task');
%     cd([datadir dirlist(i).name]);
%     mkdir('structural')
%     cd(originalpath) % go to the main path
    
    
    %data_path = [datadir dirlist(i).name '/functional/rest/'];
    if i < 52
        data_path = [datadir S.name{i} '/functional/task/'];
        data_path_s = [datadir S.name{i}  '/structural/'];
        f_path = [f_output S.name{i}  '/task/'];
        mkdir(f_path); 
    else
        data_path = [aslihan_path subj.name{i-51} '/preprocessed/'];
        data_path_s = [aslihan_path subj.name{i-51} '/preprocessed/'];
        f_path = [f_output subj.name{i-51} '/task/'];
        mkdir(f_path); 
    end
   
    
    clear matlabbatch jobs f s rf seg wrf;
    
        f = spm_select('FPList', data_path, '^f.*\.nii$');
        s = spm_select('FPList', data_path_s, '^s.*\.nii$');
        
%         % -----------------------------------------------------------
%         % 1) PREPROCESSING
%         % -----------------------------------------------------------
% % 
% %       % realign
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/01_realign_task.mat');
%         %jobs{1} = matlabbatch{1};
%         matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = cellstr(f);
%         save([data_path '/01_BATCH_realign_task.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);
% % 
% %         % slice timing
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/02_slice_task.mat');
%         % jobs{1} = matlabbatch{1};
%         a = spm_select('FPList', data_path, '^rf.*\.nii');
%         matlabbatch{1}.spm.temporal.st.scans{1} = cellstr(a);
%         save([data_path '/02_BATCH_slice_task.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);
% % 
% %         % coregistration
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/03_coreg_task.mat');
%         %jobs{1} = matlabbatch{1};
%         m = spm_select('FPList', data_path, '^mean.*\.nii$');
%         matlabbatch{1}.spm.spatial.coreg.estimate.ref = cellstr(m);
%         matlabbatch{1}.spm.spatial.coreg.estimate.source = cellstr(s);
%         save([data_path '/03_BATCH_coreg_task.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);
% % 
% % %         % segmentation
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/04_segment.mat');
%         % Update *all* tissue entries to point to your local TPM path
%         for ii = 1:6
%              matlabbatch{1}.spm.spatial.preproc.tissue(ii).tpm = {sprintf('/Users/kaankeskin/Documents/MATLAB/spm/tpm/TPM.nii,%d', ii)};
%         end
% 
%         % Provide the structural image(s) to segment
%         matlabbatch{1}.spm.spatial.preproc.channel.vols = cellstr(s);
% 
%         save([data_path '/04_BATCH_segment.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);
% % % 
% % 
% %         % normalize
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/05_normalise_task.mat');
%         %jobs{1} = matlabbatch{1};
%         rf = spm_select('FPList', data_path, '^ar.*\.nii$');
%         seg= spm_select('FPList', data_path_s, '^y.*\.nii$');
%         matlabbatch{1}.spm.spatial.normalise.write.subj.resample = cellstr(rf);
%         matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(seg);
%         save([data_path '/05_BATCH_normalise_task.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);
% % 
% %         % smooth
%         clear jobs matlabbatch;
%         load('./codes/spm_batch/06_smooth_task.mat');
%         %jobs{1} = matlabbatch{1};
%         wrf = spm_select('FPList', data_path, '^war.*\.nii$');
%         matlabbatch{1}.spm.spatial.smooth.data = cellstr(wrf);
%         save([data_path '/06_BATCH_smooth_task.mat'], 'matlabbatch');
%         spm_jobman('run', matlabbatch);

        
        % -----------------------------------------------------------
        % 2) First Level Analysis
        % -----------------------------------------------------------
         clear jobs matlabbatch;
         load('./codes/spm_batch/07_firstlevel_kontrol.mat');

         % Create a job from your loaded batch
         jobs{1} = matlabbatch{1};

          % Select the preprocessed (smoothed, normalized) NIfTI files
         fl = spm_select('FPList', data_path, '^swar.*\.nii$');

          % Set the output directory for SPM.mat
         jobs{1}.spm.stats.fmri_spec.dir = cellstr(f_path);
         
         % Emptying the condition for only response
         jobs{1}.spm.stats.fmri_spec.sess.cond = [];
         trials = load( './codes/onset.txt');
         TR = 3;
         onsets = (trials - 1) * TR ; % zero-indexed timing
         jobs{1}.spm.stats.fmri_spec.timing.units = 'secs';
         % Assign functional images to the design
         jobs{1}.spm.stats.fmri_spec.sess.scans = cellstr(fl);

         % === Condition: Outcome ===
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Outcome';
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).onset = onsets;
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).duration = 0;
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).orth = 0;
        
        % === Parametric modulator 1: PE_level2 ===
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).name = 'PE_level1';
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).param = ...
            load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_1_all.txt'));
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).poly = 1;
        
        % === Parametric modulator 2: PE_level3 ===
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).name = 'PE_level2';
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).param = ...
           load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_2_all.txt'));
        jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).poly = 1;
        
        % === No extra regressors or motion files here ===
        jobs{1}.spm.stats.fmri_spec.sess.multi = {''};
        jobs{1}.spm.stats.fmri_spec.sess.multi_reg = {''};
        jobs{1}.spm.stats.fmri_spec.sess.hpf = 128;
        jobs{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});

        % Save and run the modified batch
        save([data_path '07_BATCH_firstlevel_hgf.mat'], 'jobs');
        spm_jobman('run', jobs);

        % -----------------------------------------------------------
        % 3) Estimate the GLM
        % -----------------------------------------------------------
        clear jobs matlabbatch;
        load('./codes/spm_batch/08_estimate_kaan.mat');

        jobs{1} = matlabbatch{1};
        spmloc = fullfile(f_path, 'SPM.mat');
        jobs{1}.spm.stats.fmri_est.spmmat = cellstr(spmloc);

        save([data_path '08_BATCH_estimate_kaan.mat'], 'jobs');
        spm_jobman('run', jobs);

        % -----------------------------------------------------------
        % 4) Specify and Run Contrasts
        % -----------------------------------------------------------
        %clear jobs matlabbatch;
        load('./codes/spm_batch/09_contrasts.mat');  % This file should define your contrasts
        jobs{1} = matlabbatch{1};

        % Point SPM to the just-estimated SPM.mat
        jobs{1}.spm.stats.con.spmmat = {spmloc};
        
        % Keep existing contrastss
        jobs{1}.spm.stats.con.delete = 1; 
        jobs{1}.spm.stats.con.consess = [];

        jobs{1}.spm.stats.con.consess{1}.tcon.name = 'PE_level1';
        jobs{1}.spm.stats.con.consess{1}.tcon.weights = [0 1 0 0];  % Only PE_level1
        obs{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

        jobs{1}.spm.stats.con.consess{2}.tcon.name = 'PE_level2';
        jobs{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 1 0];  % Only PE_level1
        jobs{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

         
        
        save([data_path '09_BATCH_contrasts.mat'], 'jobs');
        spm_jobman('run', jobs);
end

toc
