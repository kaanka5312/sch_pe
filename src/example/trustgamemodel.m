% denekID = repmat(3,60,1);
% sayac = [];
% yatirim = [];
% rakip = [];
% secim= [];
% secimsure = [];
% kazanc = [];
% toplam = [];
%
%trustgame = table(denekID, sayac, yatirim,rakip, secim, secimsure, kazanc,toplam);

currentdir = pwd;
datadir = ([currentdir '\matfiles\']);
dirlist = dir(datadir);
datapath2 = ([currentdir '\results\']);
datapath3 = ([currentdir '\graphics\']);

subjects = [097 098 099 100 104 105];
%subjects = [091 093 094 096 101 102 103];

%subjects = [002 003 004 005 007 008 009 010 015 016 017 019 020 021 022 023 024 025 026 027 030 031 036 038 039 040 041 042 044 045 050 051 052 053 054 055 056 057 058 059 060 061 062 063 ...
 %   064 066 068 069 070 071 072 073 074 077 078 079 080 081 082 083 084 085 086 087 088 089 090];
%subjects(45)

for subject = subjects(1:end)
           
    subject = num2str(subject, '%03d');
    
    load ([datadir 'trustgame_' subject '.mat'])

    denekID = subject;
    A = table2array(trustgame);

%eger 5 ya da daha fazla sayida secim yapmamissa oyunu sonlandir
% if (sum(A(:,5))<= 55)
%     print("5 ya da daha fazla say?da secim yap?lmadigi icin oyun sonlandi...")
%     exit
% else
    toplam = 0; %kumulatif toplam kazanc
    alpha = []'; %learning rate
    v = []';  %tahminlenen kazanc
    v(1)= 0; %tahminlenen kazanc intial deger
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% birinci set : %80 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %gercek toplam kazanc (obtained reward)
    kazanc = A(20,8);
    x = ['1. sette toplam gerçek kazanç : ' ,num2str(kazanc)];
    disp(x)
    
    %tahminlenen kazanc (predicted gain v(t)
    
    alpha(1) = 0.5; % initial learning rate value
    %v(1) = v(1) + alpha(1)*((A(1,7) - v(1))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 2 : 20
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if trustgame.yatirim(i) == 0 %A(i,3)
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && trustgame.rakip(i) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && trustgame.rakip(i) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
    x = ['1. sette tahminlenen kazanç : ' ,num2str(sum(v))];
    disp(x)
    
    denekID = repmat(denekID,20,1);
    set1kazanc = A(1:20,7);
    set1alpha = alpha';
    set1tahminlenen = v';
    
    sonuc = table(denekID, set1kazanc, set1alpha, set1tahminlenen);
%     
%     figure; plot(sonuc.set1kazanc); hold on;
%     plot(sonuc.set1tahminlenen);
%     legend('reward', 'predicted')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ikinci set : %50 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %tahminlenen kazanc (predicted gain v(t)
    
    alpha(21) = 0.5; % initial learning rate value
    v(21) = v(20) + alpha(21)*((A(21,7) - v(20))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 22 : 40
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if trustgame.yatirim(i) == 0 %A(i,3)
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && trustgame.rakip(i) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && trustgame.rakip(i) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
    x = ['1. sette toplam gerçek kazanc : ' ,num2str(sum(trustgame.kazanc(21:40))),newline, '2. sette tahminlenen kazanç : ' ,num2str(sum(v(21:40)))];
    disp(x)
    
    
    set2kazanc = A(21:40,7);
    set2alpha = alpha(21:40)';
    set2tahminlenen = v(21:40)';
    
    sonuc.set2kazanc = set2kazanc;
    sonuc.set2alpha = set2alpha;
    sonuc.set2tahminlenen = set2tahminlenen;
    
    %
    %     figure; plot(sonuc.set2kazanc); hold on;
    %     plot(sonuc.set2tahminlenen);
    %     legend('reward', 'predicted')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ücüncü set : %80 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %tahminlenen kazanc (predicted gain v(t)
    
    alpha(41) = 0.5; % initial learning rate value
    v(41) = v(40) + alpha(41)*((A(41,7) - v(40))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 42 : 60
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if trustgame.yatirim(i) == 0 %A(i,3)
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && trustgame.rakip(i) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && trustgame.rakip(i) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
      x = ['3. sette toplam gerçek kazanc : ' ,num2str(sum(trustgame.kazanc(41:60))),newline, '3. sette tahminlenen kazanç : ' ,num2str(sum(v(41:60)))];
    disp(x)
    
    
    set3kazanc = A(41:60,7);
    set3alpha = alpha(41:60)';
    set3tahminlenen = v(41:60)';
    
    sonuc.set3kazanc = set3kazanc;
    sonuc.set3alpha = set3alpha;
    sonuc.set3tahminlenen = set3tahminlenen;
    
    %sonuc
    
    save(fullfile( datapath2 ,strcat('sonuc_',subject,'.mat')), 'sonuc')
    
    %     figure; plot(sonuc.set3kazanc); hold on;
    %     plot(sonuc.set3tahminlenen);
    %     legend('reward', 'predicted')
    


    toplamkazanc = [sonuc.set1kazanc;sonuc.set2kazanc;sonuc.set3kazanc]
    toplamtahmin = [sonuc.set1tahminlenen;sonuc.set2tahminlenen;sonuc.set3tahminlenen]
    
    %root means square error
    rmse = sqrt(immse(toplamkazanc, toplamtahmin))

    %plot the graphic
    fig = figure;
    p(1) = plot(toplamkazanc,'LineWidth', 1.5); hold on;
    p(2) = plot(toplamtahmin,'LineWidth', 1.5);
    set(fig, 'Position',[400 400 700 400])
    ylabel('Amount')
    xlabel('Trials')
    legend([p(1) p(2)], 'reward', 'predicted')
    title(strcat('Subject-',subject))
    txt = ['RMSE= ' num2str(rmse)];
    annotation('textbox',[.9 .5 .1 .2], ...
    'String',txt,'EdgeColor','none')
    
    %********do not close the figure**********
    %*****************************************
        %save as png
        whereToSave = fullfile(datapath3, strcat('graph_',subject, '.png'))
        saveas(fig,whereToSave)
        %save as fig
        whereToSave = fullfile(datapath3, strcat('graph_',subject, '.fig'))
        saveas(fig, whereToSave);
    
   
    
end

%%%%%%%%%%% ortalama sonuclar %%%%%%%%%%%%
subjects = [002 003 004 005 007 008 009 010 015 016 017 019 020 021 022 023 024 025 026 027 030 031 036 038 039 040 041 042 044 045 050 051 052 053 054 055 056 057 058 059 060 061 062 063 ...
    064 066 068 069 070 071 072 073 074 077 078 079 080 081 082 083 084 085 086 087 088 089 090 091 093 094 096 101 102 103];

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
    p(2) = plot(avg_tahmin,'LineWidth', 1.5);
    set(fig, 'Position',[400 400 700 400])
    ylabel('Amount')
    xlabel('Trials')
    legend([p(1) p(2)], 'reward', 'predicted')
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


