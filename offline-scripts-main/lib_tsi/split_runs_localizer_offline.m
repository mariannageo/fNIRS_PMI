function [split_data] = split_runs_localizer_offline(excel_filename, no_trials, no_runs, dHbx_div, NFB_Loc)
% Splits the session data into runs and stores it

fulltable=readcell(excel_filename);

for n = 1:no_runs

    run_stimtable=fulltable(1,:);
    
    ind1 = (no_trials+1) * (n-1) + 2;
    ind2 = (no_trials+1) * n + 1; 
    run_stimtable(2:(no_trials+2) , 1:3)=fulltable( ind1:ind2 , 1:3); % trigger type 1
    
    ind1 = (no_trials) * (n-1) + 2;
    ind2 = (no_trials) * n + 1; 
    run_stimtable(2:(no_trials+1) , 5:7)=fulltable( ind1:ind2 , 5:7); % trigger type 2

    split_stim_file=['stimu',num2str(n),'.xlsx'];
    xlswrite(split_stim_file, run_stimtable,'File-1' )
    
    % Divide data into runs
    ind1 = find(dHbx_div.time==run_stimtable{2,1}); % first rest trigger of a run
    ind2 = find(dHbx_div.time==run_stimtable{no_trials+2,1}); % last rest trigger of a run
    ind2 = ind2 + round(NFB_Loc.rest_durations(n, end)*dHbx_div.Fs);
        %dHbx_div.stimulus('stim_channel1').dur((no_trials+1) * n)
       
    
    dumdat = dHbx_div;
    dumdat.data=dHbx_div.data(ind1:ind2,:);
    dumdat.time=dHbx_div.time(ind1:ind2,:);
    
    split_data(n,1) = nirs.design.read_excel2stim(dumdat,split_stim_file);

    clear run_stimtable




end

end

