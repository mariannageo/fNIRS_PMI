function [SubjStats_Canonical] = GLM_PMI_offline(Hb_SDCcor)

% remove unnecessary stimulus info; '1' represents rest duration, should not be
% modeled in GLM and '7' indicates start and end of experiment and will be
% trimmed anyways
job = nirs.modules.DiscardStims;
job.listOfStims = {'stim_channel0', 'stim_channel1', 'stim_channel5', 'stim_channel7','stim_aux1','stim_aux2'};
Hb_SDCcor = job.run(Hb_SDCcor);

% change stimulus info by giving your stimuli more meaningful names
job = nirs.modules.RenameStims;
job.listOfChanges = {'stim_channel2', 'PMI'}; 

Hb_SDCcor = job.run(Hb_SDCcor);
    
% and by changing the stimulus duration, default is 1 s
for s = 1:size(Hb_SDCcor, 1)
    tbl = nirs.createStimulusTable(Hb_SDCcor(s));
    tbl.PMI.dur(:) = 15;   % in seconds

    job = nirs.modules.ChangeStimulusInfo;
    job.ChangeTable = tbl;
    Hb_SDCcor(s) = job.run(Hb_SDCcor(s));
end

Hb_SDCcor_trimmed = Hb_SDCcor;

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~ AR-IRLS GLM with Canonical HRF ~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% a priori assumptions about the shape of the HRF
% in this case we chose a canonical HRF with a peak at 6s as basis function
basis = nirs.design.basis.Canonical; % canonical basis function
                                     % other options are...
basis.peakTime = 6;    % peak 6s after stimulus onset
basis.incDeriv = true; % add first and second derivative for each regressor 
                       % in order to account for time and dispersion

job = nirs.modules.GLM;
job.type = 'AR-IRLS';  % chose the GLM type, default is AR-ILS (Barker et al., 2016); 
                       % other options are: 'OLS', 'NIRS-SPM','MV-GLM',
                       % 'Nonlinear' 
job.basis('default') = basis;
job.trend_func = @(t) nirs.design.trend.constant(t); % add constant for trend; 
                                                     % other options are legendre, dctmtx

SubjStats_Canonical = job.run(Hb_SDCcor_trimmed);

end