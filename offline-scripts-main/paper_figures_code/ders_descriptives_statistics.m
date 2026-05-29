


%% ================================
%  DERS Stats: Mean, STD, Wilcoxon, Bonferroni
% ========================================

clear; clc;

%% 1. Load wide-format DERS
T = readtable('ders_transformed.xlsx');

% List of pre/post columns
preCols  = {'NONACC_Pre','GOALS_Pre','IMPULSE_Pre','AWARE_Pre','STRAT_Pre','CLARITY_Pre','TOTAL_Pre'};
postCols = {'NONACC_Post','GOALS_Post','IMPULSE_Post','AWARE_Post','STRAT_Post','CLARITY_Post','TOTAL_Post'};

numTests = length(preCols);

% Storage variables
pVals = zeros(numTests,1);
Wstat = zeros(numTests,1);   % Wilcoxon signed-rank statistic
preMean_all = zeros(numTests,1);
preStd_all = zeros(numTests,1);
postMean_all = zeros(numTests,1);
postStd_all = zeros(numTests,1);

%% 2. Run tests
for i = 1:numTests
    preData  = T.(preCols{i});
    postData = T.(postCols{i});
    
    % Mean and std
    preMean_all(i)  = mean(preData,'omitnan');
    preStd_all(i)   = std(preData,'omitnan');
    postMean_all(i) = mean(postData,'omitnan');
    postStd_all(i)  = std(postData,'omitnan');
    
    % Wilcoxon signed-rank test
    [p,~,stats] = signrank(preData, postData);
    pVals(i)    = p;
    Wstat(i)    = stats.signedrank;  % store W statistic
end

%% 3. Multiple comparison corrections

% Bonferroni
pBonf = min(pVals * numTests, 1);

% FDR (Benjamini–Hochberg)
pFDR = mafdr(pVals,'BHFDR',true);

%% 4. Print results
fprintf('Subscale     | Pre_Mean ± STD | Post_Mean ± STD | W_stat | Raw p | Bonferroni p | FDR p\n');
fprintf('---------------------------------------------------------------------------------------------\n');

for i = 1:numTests
    fprintf('%-12s | %6.2f ± %5.2f | %6.2f ± %5.2f | %6.1f | %6.4f | %6.4f | %6.4f\n', ...
        preCols{i}, ...
        preMean_all(i), preStd_all(i), ...
        postMean_all(i), postStd_all(i), ...
        Wstat(i), ...         % print W statistic
        pVals(i), pBonf(i), pFDR(i));
end