%% ==========================================================
% CERQ ANALYSIS (Wilcoxon + FDR + Descriptives)
% ==========================================================

clear; clc;

%% ===== 1. READ WIDE DATA =====

%%% Adjust the path 
T = readtable('\offline-scripts-main\Questionnaires\CERQ.xlsx');

%% ===== 2. IDENTIFY PRE VARIABLES =====

allVars = T.Properties.VariableNames;

% Find all variables ending in '_Pre'
isPre   = endsWith(allVars, '_Pre');
preVars = allVars(isPre);

nTests = length(preVars);

%% ===== 3. PREALLOCATE VARIABLES =====

pValues   = zeros(nTests,1);
statsW    = zeros(nTests,1);

mean_pre  = zeros(nTests,1);
std_pre   = zeros(nTests,1);
mean_post = zeros(nTests,1);
std_post  = zeros(nTests,1);

%% ===== 4. LOOP: TESTS + DESCRIPTIVES =====

for i = 1:nTests
    
    preName  = preVars{i};
    postName = strrep(preName, '_Pre', '_Post');
    
    preData  = T.(preName);
    postData = T.(postName);
    
    % --- Wilcoxon signed-rank test ---
    [p,~,stats] = signrank(preData, postData);
    
    pValues(i) = p;
    statsW(i)  = stats.signedrank;
    
    % --- Descriptive statistics ---
    mean_pre(i)  = mean(preData,  'omitnan');
    std_pre(i)   = std(preData,   'omitnan');
    
    mean_post(i) = mean(postData, 'omitnan');
    std_post(i)  = std(postData,  'omitnan');
end

%% ===== 5. FDR CORRECTION (Benjamini–Hochberg) =====

alpha = 0.05;

pFDR = mafdr(pValues,'BHFDR',true);

significant = pFDR < alpha;

%% ===== 6. CLEAN SUBSCALE NAMES (REMOVE _Pre) =====

subscaleNames = erase(preVars, '_Pre');

%% ===== 7. CREATE RESULTS TABLE =====

Results = table;

Results.Subscale = subscaleNames';
Results.Mean_Pre  = mean_pre;
Results.SD_Pre    = std_pre;
Results.Mean_Post = mean_post;
Results.SD_Post   = std_post;

Results.Raw_p = pValues;
Results.FDR_p = pFDR;
Results.W_statistic = statsW;
Results.Significant_after_FDR = significant;

disp(' ')
disp('===== CERQ RESULTS =====')
disp(Results)

%% ===== 8. SAVE OUTPUT =====

writetable(Results,'CERQ_results.xlsx');

disp(' ')
disp('Analysis complete. File saved:')
disp(' - CERQ_results.xlsx')