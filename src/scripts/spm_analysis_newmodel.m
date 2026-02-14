clear all; clc;

originalpath = pwd;
%datadir = './analysis/firstlevel/';
datadir = './analysis/preprocessing/'; % './first.level/';
datadir2 = './data/data_organized/'; 
f_output = './analysis/firstlevel/'; % First-level output folder
aslihan_path = '/Volumes/Elements/SoCAT/Aslihan_TrustGame/Kontrol/';
dirlist = dir(datadir2);

S = readtable('/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv', 'Delimiter', ',');
% Preparing Aslihan's data to merge with elifozge
subj = S(52:end,"name");
pe_table = readtable('/Users/kaankeskin/projects/sch_pe/data/processed/wide_trial_pe.csv');


spm('Defaults', 'fMRI');
spm_jobman('initcfg');

tic
for i= 42:numel(pe_table.denekId) % Subject's name

    %if i == 39 || i==74 || i==44 %ecemyilmaz 74 has 3 more TR? - S.name numbers
    if i == 17 || i==63  
        disp('Breaking loop to skip subject');
        continue;  
    end
     
    display(['Working on:' int2str(pe_table.denekId(i)) ]);
    
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
    
    
    result_name = S.name{S.task_id == pe_table.denekId(i)};

    if i < 42
        data_path = [datadir result_name '/functional/task/'];
        data_path_s = [datadir result_name  '/structural/'];
        f_path = [f_output result_name  '/task/'];
        mkdir(f_path); 
    else
        data_path = [aslihan_path subj.name{i-41} '/preprocessed/'];
        data_path_s = [aslihan_path subj.name{i-41} '/preprocessed/'];
        f_path = [f_output subj.name{i-41} '/task/'];
        mkdir(f_path); 
    end
   
    
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
        %regressorFile = fullfile([datadir2 S.name{i} '/functional/task/'], 'regressor.txt'); 
        %if exist(regressorFile, 'file')
            %jobs{1}.spm.stats.fmri_spec.sess.multi_reg = {regressorFile};
        %else
            %warning('Regressor file not found: %s', regressorFile);
        %end

        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(1).name = 'pe_all';
        % jobs{1}.spm.stats.fmri_spec.sess(1).regress(1).val = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_all.txt'));  % Example values
        % 

        trials_raw = load('./codes/onset.txt'); 
        TR = 3; 
        onsets_full = (trials_raw - 1) * TR; % Convert scans to seconds
        jobs{1}.spm.stats.fmri_spec.timing.units = 'secs';

        % 2. Extract PE values for the specific subject
        sub_pe_row = pe_table(i,:);
        sub_pe_values = table2array(sub_pe_row(1, 3:end)); % 60 values

        % 3. Update conditions with 20 onsets and add PMOD
        resp_indices = [4, 10, 16]; % Response_1, Response_2, Response_3
        
        for p = 1:3
            idx = ((p-1)*20 + 1) : (p*20); % Trials 1-20, 21-40, 41-60
            c_idx = resp_indices(p);
    
            % Overwrite with the full 20 onsets to match the 20 parameters
            jobs{1}.spm.stats.fmri_spec.sess.cond(c_idx).onset = onsets_full(idx);
            jobs{1}.spm.stats.fmri_spec.sess.cond(c_idx).duration = 0;
            
            % Add the PE Modulator
            jobs{1}.spm.stats.fmri_spec.sess.cond(c_idx).pmod(1).name = sprintf('PE_Phase%d', p);
            jobs{1}.spm.stats.fmri_spec.sess.cond(c_idx).pmod(1).param = sub_pe_values(idx);
            jobs{1}.spm.stats.fmri_spec.sess.cond(c_idx).pmod(1).poly = 1;
        end
         % Emptying the condition for only response
        %  jobs{1}.spm.stats.fmri_spec.sess.cond = [];
        %  trials = load( './codes/onset.txt');
        %  TR = 3;
        %  onsets = (trials - 1) * TR ; % zero-indexed timing
        %  jobs{1}.spm.stats.fmri_spec.timing.units = 'secs';
        %  % Assign functional images to the design
        %  jobs{1}.spm.stats.fmri_spec.sess.scans = cellstr(fl);
        % 
        %  % === Condition: Outcome ===
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Outcome';
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).onset = onsets;
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).duration = 0;
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).orth = 0;
        % 
        % % === Parametric modulator 1: PE_level2 ===
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).name = 'PE';
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).param = ...
        %     load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_all_modulator.txt'));
        % jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(1).poly = 1;
        % 
        % % === Parametric modulator 2: PE_level3 ===
        % %jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).name = 'PE_level2';
        % %jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).param = ...
        % %    load(fullfile([datadir2 S.name{i} '/functional/task/'], 'pe_2_all.txt'));
        % %jobs{1}.spm.stats.fmri_spec.sess.cond(1).pmod(2).poly = 1;
        % 
        % % === No extra regressors or motion files here ===
        % jobs{1}.spm.stats.fmri_spec.sess.multi = {''};
        % jobs{1}.spm.stats.fmri_spec.sess.multi_reg = {''};
        % jobs{1}.spm.stats.fmri_spec.sess.hpf = 128;
        % jobs{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});

        % Save and run the modified batch
        save([data_path '07_BATCH_firstlevel_modulator.mat'], 'jobs');
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
            
        % Cemre's whole conditions and with regressors
         % -----------------------------------------------------------
        % MODEL-BASED fMRI CONTRASTS (PE Analysis)
        % -----------------------------------------------------------
        
        % 22) PE_Overall: Görev boyunca PE takibi (Ventral Striatum / Midbrain)
        % Anlamı: "Beynin neresi genel olarak şaşırma sinyali üretiyor?"
        jobs{1}.spm.stats.con.consess{22}.tcon.name = 'PE_Overall';
        jobs{1}.spm.stats.con.consess{22}.tcon.weights = [0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1]; 
        jobs{1}.spm.stats.con.consess{22}.tcon.sessrep = 'none';
        
        % 23) PE_Initial: Sosyal etkileşimin ilk aşamasındaki PE (Phase 1)
        % Anlamı: "Öğrenmenin en başında belirsizlik yüksekken verilen tepki."
        jobs{1}.spm.stats.con.consess{23}.tcon.name = 'PE_Initial_P1';
        jobs{1}.spm.stats.con.consess{23}.tcon.weights = [0 0 0 0 1]; 
        jobs{1}.spm.stats.con.consess{23}.tcon.sessrep = 'none';
        
        % 24) PE_Late: Sosyal etkileşimin son aşamasındaki PE (Phase 3)
        % Anlamı: "Öğrenme bittikten sonra kalan artık PE (SZ grubunda sönmemesi beklenir)."
        jobs{1}.spm.stats.con.consess{24}.tcon.name = 'PE_Late_P3';
        jobs{1}.spm.stats.con.consess{24}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]; 
        jobs{1}.spm.stats.con.consess{24}.tcon.sessrep = 'none';
        
        % 25) PE_Initial > PE_Late: Öğrenme ve Sönümlenme (Learning Extinction)
        % KRİTİK KONTRAST: "Sağlıklı kontrollerin Phase 3'te Phase 1'e göre daha az şaşırdığı bölgeler."
        % Beklenen: TPJ, pSTS ve Striatum aktivasyonu.
        jobs{1}.spm.stats.con.consess{25}.tcon.name = 'PE_Initial > PE_Late';
        jobs{1}.spm.stats.con.consess{25}.tcon.weights = [0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 -1]; 
        jobs{1}.spm.stats.con.consess{25}.tcon.sessrep = 'none';
        
        % 26) Outcome_Main_Effect: PMOD'dan bağımsız genel sonuç ekranı tepkisi
        % Anlamı: "Sadece sonucun göründüğü an (PE miktarından bağımsız genel dikkat/görsel)."
        jobs{1}.spm.stats.con.consess{26}.tcon.name = 'Outcome_Main_All';
        jobs{1}.spm.stats.con.consess{26}.tcon.weights = [0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0]; 
        jobs{1}.spm.stats.con.consess{26}.tcon.sessrep = 'none';

        % --- 27) PE_Phase2_Standalone: Orta aşamadaki PE takibi ---
        % Anlamı: "Öğrenmenin orta evresinde beynin PE'ye verdiği saf tepki."
        jobs{1}.spm.stats.con.consess{27}.tcon.name = 'PE_Phase2_Only';
        
        % Sütun Hesabı: 
        % Phase 1 PE sütunu (5) sonrasındaki her şey 1 kaydı.
        % Phase 2 PE sütunu (11. sütundaki Response_2'nin PMOD'u olduğu için) 12. sıraya denk gelir.
        w = zeros(1, 30); 
        w(12) = 1; 
        
        jobs{1}.spm.stats.con.consess{27}.tcon.weights = w;
        jobs{1}.spm.stats.con.consess{27}.tcon.sessrep = 'none';

         % Keep existing contrastss
        jobs{1}.spm.stats.con.delete = 0; 

        
         
         save([data_path '09_BATCH_contrasts.mat'], 'jobs');
        spm_jobman('run', jobs);
        
    catch exp
        yaz = ['hata: ' dirlist(i).name ' - ' exp.message '\n' ];
        fprintf(dosya, yaz);
    end
end

toc
