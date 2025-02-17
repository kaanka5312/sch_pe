function [sonuc] = income_pred(T,subj)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
T_filtered = T(T.denekId == subj,:);
denekID = subj;
A = table2array(T_filtered);

if (sum(A(:,5))<= 55)
     print("5 ya da daha fazla say?da secim yap?lmadigi icin oyun sonlandi...")
     exit
elseif (height(T_filtered) ~= 60)
    print("Task erken bitmis")
    exit
else
    sonuc = struct();
    toplam = 0; %kumulatif toplam kazanc
    alpha = zeros(1, 60);   %learning rate
    v = zeros(1, 60);   %tahminlenen kazanc
    v(1)= 0; %tahminlenen kazanc intial deger
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% birinci set : %80 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %gercek toplam kazanc (obtained reward)
    kazanc = A(20,8);
    x = ['1. sette toplam gerçek kazanç : ' ,num2str(kazanc)];
    disp(x)

    %tahminlenen kazanc (predicted gain v(t)

    alpha(1) = 0.5; % initial learning rate value
    %v(1) = v(1) + alpha(1)*((A(1,7) - v(1))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 2 : 20
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if A(i,3) == 0 % Yatirim
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && A(i,4) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && A(i,4) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
    x = ['1. sette tahminlenen kazanç : ' ,num2str(sum(v))];
    disp(x)

    set1kazanc = A(1:20,7);
    set1alpha = alpha(1:20)';
    set1tahminlenen = v(1:20)';
    
    sonuc.set1kazanc = set1kazanc;
    sonuc.set1alpha = set1alpha;
    sonuc.set1tahminlenen = set1tahminlenen;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ikinci set : %50 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %tahminlenen kazanc (predicted gain v(t)
    
    alpha(21) = 0.5; % initial learning rate value
    v(21) = v(20) + alpha(21)*((A(21,7) - v(20))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 22 : 40
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if A(i,3) == 0 %
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && A(i,4) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && A(i,4) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
    x = ['2. sette toplam gerçek kazanc : ' ,num2str(sum(T_filtered.kazanc(21:40))),newline, '2. sette tahminlenen kazanç : ' ,num2str(sum(v(21:40)))];
    disp(x)
    
    set2kazanc = A(21:40,7);
    set2alpha = alpha(21:40)';
    set2tahminlenen = v(21:40)';
    
    sonuc.set2kazanc = set2kazanc;
    sonuc.set2alpha = set2alpha;
    sonuc.set2tahminlenen = set2tahminlenen;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ücüncü set : %80 kazanma
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %tahminlenen kazanc (predicted gain v(t)
    
    alpha(41) = 0.5; % initial learning rate value
    v(41) = v(40) + alpha(41)*((A(41,7) - v(40))); %v(i) = v(i-1) + alpha*(reward(i) - v(i-1))
    
    for i = 42 : 60
        
        %eger oyuncu yatirim yapmadiysa kendisi ve rakibi 10 TL alir
        if A(i,3) == 0 %
            alpha(i) = alpha(i-1);
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            % eger oyuncu yatirim yaptiysa ve rakibi de parayi paylastiysa
            % ikisi de 30 TL alir, learning rate (alpha) epsilon kadar artar
        elseif A(i,3) == 1 && A(i,4) == 1
            alpha(i) = alpha(i-1)+ 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
            
            %eger oyuncu yatirim yaptiysa fakat rakibi parayi paylasmadiysa
            % oyuncu 0 TL, rakip 60 TL alir, learning rate (alpha) epsilon
            % kadar azalir
        elseif A(i,3) == 1 && A(i,4) == 0
            alpha(i) = alpha(i-1)- 0.025; %learning rate i epsilon kadar arttir
            v(i) = v(i-1) + alpha(i-1)*(A(i,7)-v(i-1));
        end
        
    end
      x = ['3. sette toplam gerçek kazanc : ' ,num2str(sum(T_filtered.kazanc(41:60))),newline, '3. sette tahminlenen kazanç : ' ,num2str(sum(v(41:60)))];
    disp(x)

    set3kazanc = A(41:60,7);
    set3alpha = alpha(41:60)';
    set3tahminlenen = v(41:60)';
    
    sonuc.set3kazanc = set3kazanc;
    sonuc.set3alpha = set3alpha;
    sonuc.set3tahminlenen = set3tahminlenen;
end
    
end