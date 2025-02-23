clear all; clc;

originalpath = pwd;
%datadir = './analysis/firstlevel/';
datadir = './analysis/preprocessing/'; % './first.level/';
datadir2 = './data/data_organized/'; 
f_output = './analysis/firstlevel/'; % First-level output folder
dirlist = dir(datadir2);

S = readtable('/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv', 'Delimiter', ',');
dosya = fopen('sonuclar.txt', 'a');

spm('Defaults', 'fMRI');
spm_jobman('initcfg');

tic
for i= 1:numel(S.name) % Subject's name

    if i == 39
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

    data_path = [datadir S.name{i} '/functional/task/'];
    data_path_s = [datadir S.name{i}  '/structural/'];
    f_path = [f_output S.name{i}  '/task/'];
    mkdir(f_path); 
    
    clear matlabbatch jobs f s rf seg wrf;
    
    try
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

         % Assign functional images to the design
         jobs{1}.spm.stats.fmri_spec.sess.scans = cellstr(fl);

         % ------ HERE: Insert subject-specific regressors ------
        % GEREKSIZ
        %For example, if each subject has 'regressors.txt' in their 'task' folder:
        regressorFile = fullfile([datadir2 S.name{i} '/functional/task/'], 'regressor.txt'); 
        if exist(regressorFile, 'file')
            jobs{1}.spm.stats.fmri_spec.sess.multi_reg = {regressorFile};
        else
            warning('Regressor file not found: %s', regressorFile);
        end

        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(1).name = 'pe_all';
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(1).val = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_all.txt'));  % Example values
        % 
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(2).name = 'pe_1';
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(2).val = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_1.txt'));  % Example values
        % 
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(3).name = 'pe_2';
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(3).val = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_2.txt'));  % Example values
        % 
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(4).name = 'pe_3';
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(4).val = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_3.txt'));  % Example values


        % Save and run the modified batch
        save([data_path '07_BATCH_firstlevel_kontrol.mat'], 'jobs');
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
        clear jobs matlabbatch;
        load('./codes/spm_batch/09_contrasts.mat');  % This file should define your contrasts
        jobs{1} = matlabbatch{1};

        % Point SPM to the just-estimated SPM.mat
        jobs{1}.spm.stats.con.spmmat = {spmloc};
        
         % Weaker priors all
         jobs{1}.spm.stats.con.consess{22}.tcon.name = 'Anticipation_all < (Response_all + PE_all)';
         jobs{1}.spm.stats.con.consess{22}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0.5 0 0 0 0 0 0.5 0];
         jobs{1}.spm.stats.con.consess{22}.tcon.sessrep = 'none';

        % % (Optional) Customize contrast names, weights, or type if needed here
        % % e.g.:
         % Stronger priors all
         % jobs{1}.spm.stats.con.consess{22}.tcon.name = 'Anticipation_all > (Response_all + PE_all)';
         % jobs{1}.spm.stats.con.consess{22}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1 0 0 0 0 0 -1 0 0 0 0];
         % jobs{1}.spm.stats.con.consess{22}.tcon.sessrep = 'none';

         % % Weaker priors all
         % jobs{1}.spm.stats.con.consess{23}.tcon.name = 'Anticipation_all < (Response_all + PE_all)';
         % jobs{1}.spm.stats.con.consess{23}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 1 0 0 0 0 0 1 0 0 0 0];
         % jobs{1}.spm.stats.con.consess{23}.tcon.sessrep = 'none';
         % 
         % %  Weaker priors s2
         % jobs{1}.spm.stats.con.consess{22}.tcon.name = 'Anticipation_2 > (Response_2 + PE_2)';
         % jobs{1}.spm.stats.con.consess{22}.tcon.weights = [0 0 0 0 0 0 0 0 1 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0.5 0 0];
         % jobs{1}.spm.stats.con.consess{22}.tcon.sessrep = 'none';

         % Stronger priors s2
         % jobs{1}.spm.stats.con.consess{25}.tcon.name = 'Anticipation_2 < (Response_2 + PE_2)';
         % jobs{1}.spm.stats.con.consess{25}.tcon.weights = [0 0 0 0 0 0 0 0 -1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0];
         % jobs{1}.spm.stats.con.consess{25}.tcon.sessrep = 'none';

         % % Weaker priors s3
         % jobs{1}.spm.stats.con.consess{26}.tcon.name = 'Anticipation_3 > (Response_3 + PE_3)';
         % jobs{1}.spm.stats.con.consess{26}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0];
         % matlabbatch{1}.spm.stats.con.consess{26}.tcon.sessrep = 'none';
         % 
         % % Stronger priors s3
         % jobs{1}.spm.stats.con.consess{27}.tcon.name = 'Anticipation_3 < (Response_3 + PE_3)';
         % jobs{1}.spm.stats.con.consess{27}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
         % matlabbatch{1}.spm.stats.con.consess{27}.tcon.sessrep = 'none';
         % 
         % % PE2 diff
         % jobs{1}.spm.stats.con.consess{28}.tcon.name = 'PE_2';
         % jobs{1}.spm.stats.con.consess{28}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0];
         % matlabbatch{1}.spm.stats.con.consess{28}.tcon.sessrep = 'none';
         % 
         % % PE3 diff
         % jobs{1}.spm.stats.con.consess{29}.tcon.name = 'PE_3';
         % jobs{1}.spm.stats.con.consess{29}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
         % jobs{1}.spm.stats.con.consess{29}.tcon.sessrep = 'none';
         % 
         % Keep existing contrastss
         jobs{1}.spm.stats.con.delete = 0; 

        % 
         
         save([data_path '09_BATCH_contrasts.mat'], 'jobs');
        spm_jobman('run', jobs);
        
    catch exp
        yaz = ['hata: ' dirlist(i).name ' - ' exp.message '\n' ];
        fprintf(dosya, yaz);
    end
end

fclose(dosya);
toc
