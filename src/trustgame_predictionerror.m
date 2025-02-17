 % Trust Game Kontrol Grubu 
currentdir = pwd;
datadir = ([currentdir '\matfiles\']);
dirlist = dir(datadir);
datapath2 = ([currentdir '\results\']);
datapath3 = ([currentdir '\graphics\']);



%subjects = [081 082 083 084 085 086 087 088 089 090]; %kontrol
%[002 040 042 057 058 064 071 072 073 074 077 078 079 080 ...
% 081 082 083 084 085 086 087 088 089 090]; %kontrol grubu
 
%subjects = [056 059 060 061 062 063 066 068 069 070]; %depresyon
% [003 004 005 007 008 009 010 015 016 017 019 020 021 022 023 024 025 026 027 030 ...
% 031 036 038 039 041 044 045 050 051 052 053 054 055 056 059 060 061 062 063 066 068 069 070]; %hasta grubu
 
set3tahmin_toplam = 0; set3kazanc_toplam = 0; 
set2tahmin_toplam = 0; set2kazanc_toplam = 0;
set1kazanc_toplam = 0; set1tahmin_toplam = 0;

for subject = subjects(1:end) % i = 1 : size(subjects,2)
    
    subject = num2str(subject, '%03d');
    
    load ([datapath2 'sonuc_' subject '.mat'])
    display(['Working on: sonuc_', subject ]);
    
    set1kazanc_toplam = set1kazanc_toplam + sonuc.set1kazanc;
    set1tahmin_toplam = set1tahmin_toplam + sonuc.set1tahminlenen;
    
    set2kazanc_toplam = set2kazanc_toplam + sonuc.set2kazanc;
    set2tahmin_toplam = set2tahmin_toplam + sonuc.set2tahminlenen;
    
    set3kazanc_toplam = set3kazanc_toplam + sonuc.set3kazanc;
    set3tahmin_toplam = set3tahmin_toplam + sonuc.set3tahminlenen;
    
end

avg_set1kazanc_toplam = set1kazanc_toplam / size(subjects,2);
avg_set1tahmin_toplam = set1tahmin_toplam / size(subjects,2);

avg_set2kazanc_toplam = set2kazanc_toplam / size(subjects,2);
avg_set2tahmin_toplam = set2tahmin_toplam / size(subjects,2);

avg_set3kazanc_toplam = set3kazanc_toplam / size(subjects,2);
avg_set3tahmin_toplam = set3tahmin_toplam / size(subjects,2);

avg_kazanc = [avg_set1kazanc_toplam; avg_set2kazanc_toplam; avg_set3kazanc_toplam];
avg_tahmin = [avg_set1tahmin_toplam; avg_set2tahmin_toplam; avg_set3tahmin_toplam];

%calculate the root mean square error
rmse = sqrt(immse(avg_kazanc, avg_tahmin))

%plot the graphic
    fig = figure;
    p(1) = plot(avg_kazanc,'LineWidth', 1.5); hold on;
    p(2) = plot(avg_tahmin,'LineWidth', 1.5); hold on;
    p(3) = plot(avg_tahmin - avg_kazanc, 'LineWidth', 1.5);
    set(fig, 'Position',[400 400 700 400])
    ylabel('Amount')
    xlabel('Trials')
    legend([p(1) p(2) p(3)], 'reward', 'predicted', 'PE')
    title ('Mean of all subjects')%title(strcat('Subject-',subject))
    txt = ['RMSE= ' num2str(rmse)];
    annotation('textbox',[.9 .5 .1 .2], ...
    'String',txt,'EdgeColor','none')
    
    %********do not close the figure**********
    %*****************************************
        %save as png
        whereToSave = fullfile(datapath3,'graph_mean.png');
        saveas(fig,whereToSave)
        %save as fig
        whereToSave = fullfile(datapath3,'graph_mean.fig');
        saveas(fig, whereToSave);
    
    close fig
    
    kontrol_avg_tahmin = avg_tahmin;
    kontrol_avg_kazanc = avg_kazanc;
    kontrol_PE = avg_tahmin - avg_kazanc;
    kontrol_rmse = rmse;
    
    hasta_avg_tahmin = avg_tahmin;
    hasta_avg_kazanc = avg_kazanc;
    hasta_PE = avg_tahmin - avg_kazanc;
    hasta_rmse = rmse;
    
    %plot the graphic
    fig = figure;
    p(1) = plot(kontrol_PE,'LineWidth', 1.5); hold on;
    p(2) = plot(hasta_PE,'LineWidth', 1.5); 
    set(fig, 'Position',[400 400 700 400])
    ylabel('PE')
    xlabel('Trials')
    legend([p(1) p(2)], 'Kontrol', 'Depresyon')
    title ('Gruplar Arasi PE Degerleri')%title(strcat('Subject-',subject))
    txt = {['RMSE-kontrol= ' num2str(kontrol_rmse)], ['RMSE-depresyon= ' num2str(hasta_rmse)]};
    annotation('textbox',[0.15 0.05 0.3 0.3], ...
    'String',txt,'EdgeColor','none', 'FitBoxToText','on')