function plotBetaMap(meanDat, lims, chan_layout, labels, curr_sub, data_type_str, hb_str, montage)
% this function works ONLY with the Chan_Layout_ER.jpg image and visualizes values (e.g., beta values) 
% on a channel layout
% INPUT
% meanDat: a 1xn vector for n channels
% lims:    [min, max] values of meanDat or the range that should be
%          considered for plotting 
% chan_layout: for this specific function it should be the matrix: 
% chan_layout = [0 0 0 0 0 3 0 0 0 0 0;
%                0 0 1 0 2 0 20 0 24 0 0;
%                0 0 0 0 0 19 0 0 0 0 0;
%                10 0 0 0 5 0 21 0 0 0 25;
%                0 11 0 12 0 6 0 23 0 26 0;
%                0 0 13 0 0 0 0 0 30 0 0];
% curr_sub:     subject number
% data_type_str:  describes which data type (loc or NFB) is displayed
% hb_str:       describes if HbO or HbR is displayed
% change log: 
% 16.05.2024 - David: adapted to make it work for different montages, incl.
% now a montage based createfigure_Map_PMI helper file
% 28.08.2024 - Murat: adapted for 8X8 SMA montage
    map = colormap(bluewhitered(300, [lims(1), lims(2)]));
    %% WHAT IS THIS FOR AND WHY IS IT NOT USED?    
    tmp = chan_layout;    
    for a = 1:size(meanDat, 2)
        idxTmp = find(chan_layout == a);
        tmp(idxTmp) = meanDat(a);
    end
    %%

    % plot
    figure; 
    % load image -> CHANGE PATH if necessary
    if montage == 0
        I = imread('Chan_Layout_ER_16x16.jpg'); % still need this for other montages
        % plots values on predefined positions on the image
        createfigure_Map_PMI_16x16(I, colormap(map), meanDat, lims)
    elseif montage == 1
        I = imread('Chan_Layout_ER_16x16.jpg'); % template image, could replace or gray out
        createfigure_Map_PMI_8x8(I, colormap(map), meanDat, lims)
    elseif montage == 2
        I = imread('Optode_Layout_8x8_Motor_Imagery.png'); % simple Aurora image, must be replaced
        createfigure_Map_Motor_Imagery_8x8(I, colormap(map), meanDat, lims) %
    end

    colormap(map);
    hold on
    %clim([lims(1), lims(2)]);
    caxis([lims(1), lims(2)]);
    set(gca,'xtick',[])
    set(gca,'xticklabel',[])
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    colormap(map); 
    %clim([lims(1), lims(2)]);
    caxis([lims(1), lims(2)]);
    hBar = colorbar('southoutside');
    hBar.Label.String = {'BETAS', 'red channels: no NFB, pruned', 'green channels: NFB, not pruned', 'blue channels: NFB, pruned'};
    if(isempty(labels))
        title(['Subject: ' curr_sub ', ' hb_str ', ' data_type_str], 'FontSize', 10);
    else
        title([labels ', ' hb_str ', ' data_type_str], 'FontSize', 10);
    end
end