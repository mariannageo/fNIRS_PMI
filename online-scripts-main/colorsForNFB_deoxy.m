function FBcolor = colorsForNFB_deoxy(data, map, threshold)
% the function colorsForNFB_deoxy generates a RGB color (FBcolor) for a given data
% point data in relation to a given threshold (i.e., min value from a
% localizer)

for i = 1:length(data)
    % only colors for negative values (HbR)
    if data(i) < 0
        perc = data(i)/threshold;
        tmp = abs(round(perc*size(map, 1))); %% included absolute value to account for positive threshold
        if tmp > size(map, 1)
            tmp = size(map, 1);
        end
        if tmp == 0
            tmp = 1;
        end
        FBcolor(i, :) = map(tmp, :).*255;
    else
        FBcolor(i, :) = [255 255 255]; % white if zero or positive value
    end
end

end
