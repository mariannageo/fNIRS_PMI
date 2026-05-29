function [raw] = missingtrigger (raw, data_type)
% Handles the missing trigger label '0', which is the initial trigger when the waiting screen is shown for the first time;
% 1) imputes stimulus data based on data from another recording (with shorted onset duration) and
% 2) discard recordings that lack all triggers

% The script patches the missing onset stamp for the start of the experiment
% by using the smallest value from the other subjcect/recordings in the same
% session and data type (i.e., localizer or NFB)

onsets = [];
missrecording = [];
recordings = [];
discardrecording = [];

if data_type < 2 % check data is "Localizer" or "NFB WITH breaks"

    for k=1:length(raw)

        listofstim = str2double(raw(k,1).stimulus.keys); % get the list of stimulus triggers for recordings

        if isempty(listofstim)
            discardrecording = [discardrecording,k]; % get the list of recordings that are missing all stimulus triggers

        elseif raw(k,1).stimulus.count == 5 % get the recordings with full stimulus triggers

            onsets=[onsets, min(raw(k,1).stimulus('0').onset)]; % get the onsets
            recordings=[recordings,k]; % collect the recording numbers ('P) with full stimulus triggers

        elseif raw(k,1).stimulus.count == 4

            if ~ismember(0,listofstim) % check if trigger type 0 is present in the stimulus trigger list
                missrecording=[missrecording, k];

            elseif ~all(ismember([1 2 5],listofstim)) % check experimental stimulus triggers are present
                discardrecording = [discardrecording,k]; % get the list of recordings that are missing experimental stimulus triggers
            end

        elseif ~all(ismember([1 2 5],listofstim)) % check experimental stimulus triggers are present
            discardrecording = [discardrecording,k]; % get the list of recordings that are missing experimental stimulus triggers
        end

    end

elseif data_type == 2 % data is "NFB WITHOUT breaks"

    for k=1:length(raw)

        listofstim = str2double(raw(k,1).stimulus.keys); % get the list of stimulus triggers for recordings

        if isempty(listofstim)
            discardrecording = [discardrecording,k]; % get the list of recordings that are missing all stimulus triggers

        elseif raw(k,1).stimulus.count == 4 % get the recordings with full stimulus triggers

            onsets=[onsets, min(raw(k,1).stimulus('0').onset)]; % get the onsets
            recordings=[recordings,k]; % collect the recording numbers ('P) with full stimulus triggers

        elseif raw(k,1).stimulus.count == 3

            if ~ismember(0,listofstim) % check if trigger type 0 is present in the stimulus trigger list
                missrecording=[missrecording, k];

            elseif ~all(ismember([1 2],listofstim)) % check experimental stimulus triggers are present
                discardrecording = [discardrecording,k]; % get the list of recordings that are missing experimental stimulus triggers
            end

        elseif ~all(ismember([1 2],listofstim)) % check experimental stimulus triggers are present
            discardrecording = [discardrecording,k]; % get the list of recordings that are missing experimental stimulus triggers
        end

    end
end


minonset = min(onsets); % get minimum timestamp for stimulus 0
minonsetrecording = recordings(find(minonset==onsets)); % get the recording index that has minimum timestamp

for ii=missrecording
    raw(ii,1).stimulus('0') = raw(minonsetrecording,1).stimulus('0'); % patch stimulus trigger for stimulus type 0 in missing subjects
end

raw(discardrecording) = []; % discard recordings that are missing experimental stimulus triggers

end