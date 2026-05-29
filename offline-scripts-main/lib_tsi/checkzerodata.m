function [raw] = checkzerodata (raw)
% Finds zero amplitudes in the raw data and interpolates them  

dat = raw.data;
nch = size(dat,2);

for ch = 1:nch
    
    dumdat=dat(:,ch); % get intensity data

    if any(dumdat == 0) % check if intensity has a "zero" data
        
        zind = [];
        dd = (dumdat == 0);
        for k = 1:length(dumdat)
            zind = [zind, num2str(dd(k))]; % get indices of "zeros"
        end
        
        st = strfind(zind,('01')) + 1; % start index of zero segment
        fin = strfind(zind,('10')); % final index of zero segment

        for i = 1 : length(st)            
            interp_data = spline([st(i)-1 fin(i)+1],[dumdat(st(i)-1) dumdat(fin(i)+1)], [st(i):1:fin(i)]);
            dumdat (st(i):fin(i)) = interp_data;
        end

        dat(:,ch) = dumdat;
    end

    raw.data = dat;
end

end