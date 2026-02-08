% Second level analysis 
% List of subject images for each group

clear all; clc;
S = readtable('/Users/kaankeskin/projects/sch_pe/data/raw/subjects_list.csv', 'Delimiter', ',');
path1='/Volumes/Elements/SoCAT/ElifOzgeSCH/SCHdata/analysis/firstlevel/';

% İlgilendiğimiz tüm PE kontrastlarını döngüye alalım
% 22: Overall, 23: Initial, 24: Late, 25: Initial > Late, 27: Phase 2 Standalone
contrasts_to_run = [26,27];

for c_num = contrasts_to_run
    con_name = sprintf('con_%04d.nii', c_num);
    display(['Running Second Level for: ' con_name]);

    % 1. Denekleri ve Dosyaları Hazırla
    all_files = cellfun(@(f) fullfile(path1, f, 'task', con_name), S.name, 'UniformOutput', false);
    
    % Hariç tutulacak deneklerin isimlerini buraya yaz (Index yerine isim daha güvenlidir)
    exclude_names = {'b.akkoc', 's.kanik', 'u.aydin', 'ecemyilmaz'};
    keep_mask = ~ismember(S.name, exclude_names);

    % Filtrelenmiş Tablo ve Dosyalar
    S_final = S(keep_mask, :);
    files_final = all_files(keep_mask);
    
    L = logical(S_final.group); % 1=SZ, 0=HC
    sz_scans = files_final(L);
    hc_scans = files_final(~L);
    
    % 2. Directory Ayarı
    secondLevelDir = fullfile('./secondlevel', ['GroupComparison_' sprintf('%04d', c_num)]);
    if ~exist(secondLevelDir, 'dir'), mkdir(secondLevelDir); end
    
    clear matlabbatch;
    matlabbatch{1}.spm.stats.factorial_design.dir = {secondLevelDir};
    
    % Two-sample t-test design specification
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = sz_scans;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = hc_scans;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1; % Genellikle unequal varsayılır
    matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
    
    % Covariates
    % Cinsiyet
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c = double(S_final.sex);
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Sex';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;
    
    % Yaş
    matlabbatch{1}.spm.stats.factorial_design.cov(2).c = double(S_final.age);
    matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'Age';
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;
    
    % 5. Model Estimation & Running
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(secondLevelDir, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    save(fullfile(secondLevelDir, 'batch_job.mat'), 'matlabbatch');
    spm_jobman('run', matlabbatch);

end

%% One sample t-test for activation 
con_name = 'con_0023.nii';

groups = {'SZ', 'HC'};
for g = 1:2
    is_group = (S_final.group == (2-g)); % 1=SZ, 0=HC mantığına göre
    current_files = cellfun(@(f) [fullfile(path1, f, 'task', con_name) ',1'], ...
                    S_final.name(is_group), 'UniformOutput', false);
    
    output_dir = fullfile('./secondlevel', ['OneSample_' groups{g} '_' con_name]);
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
    
    clear matlabbatch;
    matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = current_files;
    
    % Kovaryatlar (Opsiyonel ama önerilir: Yaş ve Cinsiyet)
    %matlabbatch{1}.spm.stats.factorial_design.cov(1).c = double(S_final.sex(is_group));
    %matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Sex';
    %matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
    %matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;

    % Yaş
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).c = double(S_final.age);
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'Age';
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;
    %matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;
    
    % Tahmin (Estimation)
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(output_dir, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    spm_jobman('run', matlabbatch);
end