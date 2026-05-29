function [tsi_data] = tsi2nirs_NFB_offline(Hb_SDCcor, oxyNFB_NFBdat, deoxyNFB_NFBdat)
% This function takes TSI parsed deoxyHB data and inserts as the
% preprocessed dat stored in Hb_SDCcor. The output of this function will
% be feed into nirstoolbox GLM to calculate the beta values, which in turn
% will be used to select the target channels and NFB threshold.
% inputs:
% Hb_SDCcor - splitted aurora data
% NFB_LOC - saved TSI data

no_runs=size(deoxyNFB_NFBdat.rest_durations,1);
no_trials=size(deoxyNFB_NFBdat.NFB_dat_deoxy,2)/size(deoxyNFB_NFBdat.rest_durations,1);

% HBR
restr=deoxyNFB_NFBdat.Rest_dat_deoxy;
taskr=deoxyNFB_NFBdat.NFB_dat_deoxy;
restr=transpose(reshape(restr,[no_trials+1,no_runs]));
taskr=transpose(reshape(taskr,[no_trials,no_runs]));

% HBO
resto=oxyNFB_NFBdat.Rest_dat_oxy;
tasko=oxyNFB_NFBdat.NFB_dat_oxy;
resto=transpose(reshape(resto,[no_trials+1,no_runs]));
tasko=transpose(reshape(tasko,[no_trials,no_runs]));

for r=1:no_runs

    % HBR

    % correct the data - NFB data had a buffer issue, therefore it is longer
    % than it is supposed to be. 
    for k=1:no_trials
        rr=restr{r,k};
        tt=taskr{r,k};

        dind=find(all(tt==rr(:,end))==1);

        tt(:,1:dind-1)=[];
        taskr{r,k}=tt;
    end

    dathbr=[];

    for k=1:no_trials % number of trials
        a=restr{r,k}';
        dathbr=[dathbr;a]; sttask(k) = length(dathbr);
        a=taskr{r,k}';
        dathbr=[dathbr;a];
    end
    dathbr = [dathbr; restr{r,end}'];

    %HBO

    % same buffer issue is solved here for older measurements
    for k=1:no_trials
        rr=resto{r,k};
        tt=tasko{r,k};

        dind=find(all(tt==rr(:,end))==1);

        tt(:,1:dind-1)=[];
        tasko{r,k}=tt;
    end

    dathbo=[];
    for k=1:no_trials % number of trials
        a=resto{r,k}';
        dathbo=[dathbo;a];
        a=tasko{r,k}';
        dathbo=[dathbo;a];
    end
    dathbo = [dathbo; resto{r,end}'];

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

    if length(tsi_data(r,1).time)> length(tsi_data(r,1).data)
        tsi_data(r,1).time(length(tsi_data(r,1).data)+1:end)=[];
    elseif length(tsi_data(r,1).time) < length(tsi_data(r,1).data)
        tsi_data(r,1).data(length(tsi_data(r,1).time)+1:end,:)=[];
    end

    clear sttask
end

end

