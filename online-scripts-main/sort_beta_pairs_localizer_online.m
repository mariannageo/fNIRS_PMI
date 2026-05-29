%09.01 Marianna adapted for 1 run recordings as well

function [betas_hbr_loc_dlPFC_left_sorted, betas_hbr_loc_dlPFC_left_chan_idcs] = sort_beta_pairs_localizer_online(betas_hbr_loc_dlPFC_left)

%[betas_hbr_loc_dlPFC_left_sorted, betas_hbr_loc_dlPFC_left_chan_idcs]

if size(betas_hbr_loc_dlPFC_left, 2) == 1

rowIndices = (1:size(betas_hbr_loc_dlPFC_left, 1))'; % Create a column vector of row indices
betas_hbr_loc_dlPFC_left = [betas_hbr_loc_dlPFC_left, rowIndices]; % Append as the last column

sorted_data = sortrows(betas_hbr_loc_dlPFC_left, 1);
betas_hbr_loc_dlPFC_left_sorted = sorted_data(:,1);
betas_hbr_loc_dlPFC_left_chan_idcs = sorted_data(:,2);

elseif size(betas_hbr_loc_dlPFC_left, 2) == 2
    
rowIndices = (1:size(betas_hbr_loc_dlPFC_left, 1))'; % Create a column vector of row indices
betas_hbr_loc_dlPFC_left = [betas_hbr_loc_dlPFC_left, rowIndices]; % Append as the last column

% Create a new column initialized with zeros
betas_hbr_loc_dlPFC_left_flag = [betas_hbr_loc_dlPFC_left, zeros(size(betas_hbr_loc_dlPFC_left,1), 1)];
% Find rows where both columns are negative
rowsWithNegatives = (betas_hbr_loc_dlPFC_left(:,1) < 0) & (betas_hbr_loc_dlPFC_left(:,2) < 0);
% Set the new column to 1 for those rows
betas_hbr_loc_dlPFC_left_flag(rowsWithNegatives, 4) = 1;


averages = mean(betas_hbr_loc_dlPFC_left_flag(:, 1:2), 2);

% Add the averages as a new column
betas_hbr_loc_dlPFC_left_with_avg = [betas_hbr_loc_dlPFC_left_flag, averages];

disp('Matrix with Averages Added:');
disp(betas_hbr_loc_dlPFC_left_with_avg);

% Extract rows where the 3rd column is 1
rowsToSort_neg = betas_hbr_loc_dlPFC_left_with_avg(betas_hbr_loc_dlPFC_left_with_avg(:, 4) == 1, :);
% Sort these rows based on the 5th column
sortedRows_negativebetas = sortrows(rowsToSort_neg, 5);



% Extract rows where the 3rd column is 0
rowsToSort = betas_hbr_loc_dlPFC_left_with_avg(betas_hbr_loc_dlPFC_left_with_avg(:, 4) == 0, :);
% Sort these rows based on the 5th column
sortedRows = sortrows(rowsToSort, 5);

combinedSortedRows = [sortedRows_negativebetas; sortedRows];

betas_hbr_loc_dlPFC_left_sorted = combinedSortedRows(:, 5);
betas_hbr_loc_dlPFC_left_chan_idcs = combinedSortedRows(:, 3); % Extract 3rd column

else
    disp('Adapt the sort beta pairs script for more than 2 runs')

end

