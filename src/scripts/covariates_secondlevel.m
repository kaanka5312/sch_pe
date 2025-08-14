% Second level analysis 
% List of subject images for each group

clear all; clc;
S = readtable('/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv', 'Delimiter', ',');
path1='/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/analysis/firstlevel/';
contrasts = arrayfun(@num2str, 27, 'UniformOutput', false);

for cont = 1:numel(contrasts)
    path2=['/task/con_00' contrasts{cont} '.nii'];
    %path2=['/task/beta_00' contrasts{cont} '.nii'];

    files = cellfun(@(f) fullfile(path1, f, path2), S.name, 'UniformOutput', false);
    L = logical(S.group);
    
    sz_scans = files(L); hc_scans = files(~L);
    sz_scans([2, 23]) = []; %remove b.akkoc and s.kanik for now
    hc_scans([18, 43]) = []; %remove u.aydin and ecemyilmaz for now
    
    % Specify directory for second-level results
    secondLevelDir = ['./secondlevel/Cov_twoSampleT_00' contrasts{cont}];
    if ~exist(secondLevelDir, 'dir')
        mkdir(secondLevelDir);
    end
    
    clear matlabbatch;
    matlabbatch{1}.spm.stats.factorial_design.dir = {secondLevelDir};
    
    % Two-sample t-test design specification
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = sz_scans; 
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = hc_scans;
    
    % Covariates
    cov_age = double(S.age);
    cov_sex = double(S.sex);
    cov_doi = double(S.DoI);
    
    % Remove s.kanik and ecemyilmaz (indices 23 and 43)
    exclude_idx = [9, 18, 44, 39];
    cov_sex(exclude_idx) = [];
    %cov_doi(exclude_idx) = [];

    % Sex
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c = cov_sex;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Sex';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;
   
    % DoI
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).c = cov_doi;
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'DOI';
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;
    
    % (Optional) Equal/unequal variance assumption
    % By default, SPM uses unequal variance (var_equal = 0).
    % If you want to assume equal variances, set:
    % matlabbatch{1}.spm.stats.factorial_design.des.t2.voi = 1;
    
    % Masking, grand mean scaling, etc.
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1; 
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    % Model estimation (2nd job)
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(secondLevelDir, 'SPM.mat')};
    
    % Save and run
    save(fullfile(secondLevelDir, 'TwoSampleT_Batch.mat'), 'matlabbatch');
    spm_jobman('run', matlabbatch);

    % One sample t-test for finding activation related parts
    % HC 
    clear jobs matlabbatch;

    secondLevelDir = ['./secondlevel/Cov_HC_oneSampleT_00' contrasts{cont}];
    if ~exist(secondLevelDir, 'dir')
        mkdir(secondLevelDir);
    end

    matlabbatch{1}.spm.stats.factorial_design.dir = {secondLevelDir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = hc_scans ;
    %matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFT', {}, 'iCC', {});
    
    % Covariates
    cov_sex = double(S.sex);
    
    
    % Extract HC-only covariates (remove index 43)
    %hc_cov_age = cov_age(~L); hc_cov_age([18, 43]) = [];
    hc_cov_sex = cov_sex(~L); hc_cov_sex([18, 43]) = [];
    
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c = hc_cov_sex;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Sex';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFT = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;
    
    
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(secondLevelDir, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    spm_jobman('run', matlabbatch);
    
    % SZ 
    clear jobs matlabbatch;

    secondLevelDir = ['./secondlevel/Cov_SZ_oneSampleT_00' contrasts{cont}];
    if ~exist(secondLevelDir, 'dir')
        mkdir(secondLevelDir);
    end

    matlabbatch{1}.spm.stats.factorial_design.dir = {secondLevelDir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = sz_scans ;
    %matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFT', {}, 'iCC', {});
    
    % Extract SZ-only covariates
    cov_sex = double(S.sex);
    cov_doi = double(S.DoI);

    sz_cov_sex = cov_sex(L); sz_cov_sex([2,23]) = [];
    sz_cov_doi = cov_doi(L); sz_cov_doi([2,23]) = [];
    
   
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c = sz_cov_sex;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Sex';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFT = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;
    
    matlabbatch{1}.spm.stats.factorial_design.cov(2).c = sz_cov_doi;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'DoI';
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFT = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;
        
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(secondLevelDir, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    spm_jobman('run', matlabbatch);

end