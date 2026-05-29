%% ==========================================================
% ERQ PRE-POST ANALYSIS (Wilcoxon + FDR + W statistic)
% ===========================================================

clear; clc;

%% 1) READ EXCEL FILE
filename = '\offline-scripts-main\Questionnaires\ERQ.xlsx';
T = readtable(filename);

%% 2) CLEAN VARIABLE NAMES
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);

% Rename first two columns (assumed ID and Session)
T.Properties.VariableNames{1} = 'ID';
T.Properties.VariableNames{2} = 'Session';

%% 3) CONVERT SESSION TO PRE/POST
T.Session = categorical(T.Session,[1 3],{'Pre','Post'});

%% 4) KEEP ONLY SCALE VARIABLES
disp(T.Properties.VariableNames)

SuppVar  = T.Properties.VariableNames{end-1};
ReappVar = T.Properties.VariableNames{end};

Tsmall = T(:, {'ID','Session',SuppVar,ReappVar});

%% 5) RESHAPE LONG → WIDE
WideTable = unstack(Tsmall, {SuppVar,ReappVar}, 'Session');
WideTable = sortrows(WideTable,'ID');

%% 6) EXTRACT VARIABLES
vars = WideTable.Properties.VariableNames;

Supp_Pre  = WideTable.(vars{2});
Supp_Post = WideTable.(vars{3});
Reap_Pre  = WideTable.(vars{4});
Reap_Post = WideTable.(vars{5});

n = height(WideTable);

%% 7) WILCOXON SIGNED-RANK TESTS

% --- Suppression ---
[p_supp,~,stats_supp] = signrank(Supp_Pre, Supp_Post);
W_supp = stats_supp.signedrank;
z_supp = stats_supp.zval;
r_supp = abs(z_supp)/sqrt(n);

% --- Reappraisal ---
[p_reap,~,stats_reap] = signrank(Reap_Pre, Reap_Post);
W_reap = stats_reap.signedrank;
z_reap = stats_reap.zval;
r_reap = abs(z_reap)/sqrt(n);

%% 8) FDR CORRECTION (Benjamini–Hochberg)

pvals = [p_supp; p_reap];

pvals_fdr = mafdr(pvals,'BHFDR',true);

p_supp_fdr = pvals_fdr(1);
p_reap_fdr = pvals_fdr(2);

%% 9) DESCRIPTIVE STATISTICS (Mean & SD)

% --- Suppression ---
mean_supp_pre  = mean(Supp_Pre,  'omitnan');
std_supp_pre   = std(Supp_Pre,   'omitnan');

mean_supp_post = mean(Supp_Post, 'omitnan');
std_supp_post  = std(Supp_Post,  'omitnan');

% --- Reappraisal ---
mean_reap_pre  = mean(Reap_Pre,  'omitnan');
std_reap_pre   = std(Reap_Pre,   'omitnan');

mean_reap_post = mean(Reap_Post, 'omitnan');
std_reap_post  = std(Reap_Post,  'omitnan');

%% 10) CREATE RESULTS TABLE

Results = table;

Results.Scale = {'Suppression'; 'Reappraisal'};
Results.Raw_p = [p_supp; p_reap];
Results.FDR_p = [p_supp_fdr; p_reap_fdr];
Results.W_statistic = [W_supp; W_reap];
Results.Effect_r = [r_supp; r_reap];

Results.Mean_Pre  = [mean_supp_pre;  mean_reap_pre];
Results.SD_Pre    = [std_supp_pre;   std_reap_pre];
Results.Mean_Post = [mean_supp_post; mean_reap_post];
Results.SD_Post   = [std_supp_post;  std_reap_post];

disp(' ')
disp('===== RESULTS =====')
disp(Results)

%% 11) SAVE OUTPUT FILES
writetable(WideTable,'ERQ_wide.xlsx');
writetable(Results,'ERQ_results.xlsx');

disp(' ')
disp('Analysis complete. Files saved:')
disp(' - ERQ_wide.xlsx')
disp(' - ERQ_results.xlsx')