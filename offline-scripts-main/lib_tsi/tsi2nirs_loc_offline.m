function [tsi_data] = tsi2nirs_loc_offline(Hb_SDCcor, NFB_Loc)
% This function takes TSI parsed deoxyHB data and inserts as the
% preprocessed dat stored in Hb_SDCcor. The output of this function will
% be feed into nirstoolbox GLM to calculate the beta values, which in turn
% will be used to select the target channels and NFB threshold.
% inputs:
% Hb_SDCcor - splitted aurora data
% NFB_LOC - saved TSI data
for r=1:size(NFB_Loc.NFB_dat_deoxy,1)

    % HBR
    restr=NFB_Loc.Rest_dat_deoxy;
    taskr=NFB_Loc.NFB_dat_deoxy;
    dathbr=[];
    for k=1:length(NFB_Loc.NFB_dat_deoxy) % number of trials
        a=restr{r,k};
        dathbr=[dathbr;a]; sttask(k) = length(dathbr);
        a=taskr{r,k};
        dathbr=[dathbr;a];
    end
    dathbr = [dathbr; restr{r,end}];

    %HBO
    resto=NFB_Loc.Rest_dat_oxy;
    tasko=NFB_Loc.NFB_dat_oxy;
    dathbo=[];
    for k=1:length(NFB_Loc.NFB_dat_oxy) % number of trials
        a=resto{r,k};
        dathbo=[dathbo;a];
        a=tasko{r,k};
        dathbo=[dathbo;a];
    end
    dathbo = [dathbo; resto{r,end}];

    % Combine HBO and HBR
    dat=[];
    for k=1:size(dathbr,2)
        dat=[dat dathbo(:,k) dathbr(:,k)];
    end
    
    %remove duplicated data
    duplicate_ind = find(diff(dat(:,1))==0);
    dat(duplicate_ind,:) = []; 

    tsi_data(r,1)=Hb_SDCcor(r);

    % tasktrigger index
    sttask=sttask+1;
    %change data
    tsi_data(r,1).data=dat;
    %change time
    tsi_data(r,1).time(length(dat)+1:end)=[];
    %change triggers
    tsi_data(r,1).stimulus('stim_channel2').onset = tsi_data(r,1).time(sttask);

    % trigger metadata
    a=tsi_data(r,1).stimulus('stim_channel2').metadata;
    a.onset = tsi_data(r,1).stimulus('stim_channel2').onset;
    tsi_data(r,1).stimulus('stim_channel2').metadata = a;

    clear sttask
end

end

