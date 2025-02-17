currentdir = pwd;
datadir = ([currentdir '\results\']);

load ([datadir 'PEall_kontrol.mat'])
load ([datadir 'PEall_depresyon.mat'])

PEnor = zeros(size(PEall,1), size(PEall,2));

for i = 1 : size(PEall,2)

    %to normalize in [a,b]
    % x = [b-a]*((x-minx)/(maxx-minx)) +a
maxPE = max(PEall(:,i));
minPE = min(PEall(:,i));

x = 2*(PEall(:,1)-minPE)/(maxPE-minPE)-1;

%sinyali kuvvetlendirmek için 1 e böl
PEnor (:,i) = 1./x;
%otherwise
%PEnor(:,i+1) = x;

end



% A = [];
% for j = 1 : size(PEnor,1)
%     
% A = vertcat(A,repmat(PEnor(j,:),8,1));
% end

% %anticipation onsetleri
% ind = [4 12 20 28 36 44 52 60 68 76 87 95 103 111 119 127 135 143 151 159 170 178 186 194 202 210 218 226 234 242 ...
% 253 261 269 277 285 293 301 309 317 325 336 344 352 360 368 376 384 392 400 408 419 427 435 443 451 459 467 475 483 491]';
% 
% ind = ind+1; %response onsetleri icin +1

cofoundmatrix = zeros(480, size(PEall,2));

for i = 1 : size(PEall,2)
    game =zeros(60,8); %oyun matrisi olustur, her bir kolon bir ekran, decision ve jitter-fixatition icin 2ser ekran toplam 8
    game (:, 5) = PEnor(:,i); %normalize edilmis degerleri response kolonuna yerle?tir
    
    B = game'; %converts matrix to an array 480x1
    B = B(:)'; %index yerlerinde PE degerleri olacak, geri kalanlar? 0
    B= B';
    
    cofoundmatrix(:,i) = B; %matrisin her bir kolonu bir kisi icin olan PE confounding factorleri temsil eder
    
end
