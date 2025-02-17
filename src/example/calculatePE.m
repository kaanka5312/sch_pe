
currentdir = pwd;
datadir = ([currentdir '\matfiles\']);
dirlist = dir(datadir);
datapath2 = ([currentdir '\results\']);
datapath3 = ([currentdir '\graphics\']);


subjects = [002 042 057 058 064 071 072 073 074 077 078 079 080 ...
            081 082 083 084 085 086 087 088 089 090 ...
            091 093 094 096 097 098 099 100 101 102 103 104 105]; %kontrol grubu
 
subjects = [003 004 007 008 009 010 015 016 017 019 020 021 ...
            022 023 024 025 026 027 030 031 036 038 ...
            039 041 044 045 050 051 052 053 054 055 ...
            056 059 060 061 066 068 069 070]; %hasta grubu

 
set3PE = 0;
set2PE = 0; 
set1PE = 0; 
PEall = [];
PEort  =[];

for subject = subjects(1:end) % i = 1 : size(subjects,2)
    
    subject = num2str(subject, '%03d');
    
    load ([datapath2 'sonuc_' subject '.mat'])
    display(['Working on: sonuc_', subject ]);
    
    set1PE = abs(sonuc.set1kazanc - sonuc.set1tahminlenen);
    set2PE = abs(sonuc.set2kazanc - sonuc.set3tahminlenen);
    set3PE = abs(sonuc.set3kazanc - sonuc.set3tahminlenen);
    
    PE = vertcat (set1PE,set2PE,set3PE);
    
    PEall = horzcat(PEall, PE);
    
    %save(fullfile( datapath2 ,strcat('PE_',subject,'.mat')), 'PE')
   % ort = sum(vertcat(set1PE,set2PE,set3PE))/60;
    
    %PEort = vertcat(PEort, ort);
end