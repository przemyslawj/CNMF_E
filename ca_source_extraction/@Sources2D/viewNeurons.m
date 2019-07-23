function ind_del = viewNeurons(obj, ind, C2, folder_nm)
%% view all components and delete components manually. it shows spatial
%   components in the full-frame and zoomed-in view. It also shows temporal
%   components
%% input:
%   ind: vector, indices of components to be displayed, no bigger than the maximum
%       number of neurons
%   C2:  K*T matrix, another temporal component to be displayed together
%       with the esitmated C. usually it is C without deconvolution.

%% Author: Pengcheng Zhou, Carnegie Mellon University, 2016

if ~exist('ind', 'var') || isempty(ind)
    % display all neurons if ind is not specified.
    ind = 1:size(obj.A, 2);
elseif ind==-1
    ind = size(obj.A,2):-1:1;
end
if ~exist('C2', 'var'); C2=[]; end

if exist('folder_nm', 'var')&&(~isempty(folder_nm))
    % create a folder to save images
    save_img = true;
    cur_cd = cd();
    if ~exist(folder_nm, 'dir'); mkdir(folder_nm);
    else
        fprintf('The folder has been created and old results will be overwritten. \n');
    end
    cd(folder_nm);
else
    save_img = false;
end

% obj.delete(sum(obj.A>0, 1)<max(obj.options.min_pixel, 1));

Amask = (obj.A~=0);
ind_trim = false(size(ind));    % indicator of trimming neurons
ind_del = false(size(ind));     % indicator of deleting neurons
ctr = obj.estCenter();      %neuron's center
gSiz = obj.options.gSiz;        % maximum size of a neuron

outlines = obj.get_contours(0.5);

% time
T = size(obj.C, 2);
t = 1:T;
if ~isnan(obj.Fs)
    t = t/obj.Fs;
    str_xlabel = 'Time (Sec.)';
else
    str_xlabel = 'Frame';
end

%% keep the log information
if ~save_img
    try
        log_file =  obj.P.log_file;
        flog = fopen(log_file, 'a');
        log_data = matfile(obj.P.log_data, 'Writable', true); %#ok<NASGU>
        manual_intervention.before = obj.obj2struct();
        
        fprintf(flog, '[%s]\b', get_minute());
        fprintf(flog, 'Start manual interventions:\n');
    end
end

%% start viewing neurons
h=figure('position', [100, 100, 1024, 512]);
m=1;
prev_m = 0;
while and(m>=1, m<=length(ind))
    if prev_m ~= m
        eventIdx = 1;
        prev_m = m;
    end
    %% full-frame view
    subplot(221); cla;
    obj.image(obj.A(:, ind(m)).*Amask(:, ind(m))); %
    axis equal; axis off;
    if ind_del(m)
        title(sprintf('Neuron %d', ind(m)), 'color', 'r');
    else
        title(sprintf('Neuron %d', ind(m)));
    end
    %% zoomed-in view
    subplot(222); cla;
    obj.image(obj.A(:, ind(m)).*Amask(:, ind(m))); %
    %     imagesc(reshape(obj.A(:, ind(m)).*Amask(:,ind(m))), obj.options.d1, obj.options.d2));
    axis equal; axis off;
    x0 = ctr(ind(m), 2);
    y0 = ctr(ind(m), 1);
    if ~isnan(x0)
        xlim(x0+[-gSiz, gSiz]*2);
        ylim(y0+[-gSiz, gSiz]*2);
    end
    
    %% temporal components
    subplot(2,2,3:4);cla;
    
    % TODO If the recording too long, show a subset
    
    if ~isempty(C2)
        plot(t, C2(ind(m), :)*max(obj.A(:, ind(m))), 'linewidth', 2); hold on;
        plot(t, obj.C(ind(m), :)*max(obj.A(:, ind(m))), 'r');
    else
        
        plot(t, obj.C(ind(m), :)*max(obj.A(:, ind(m))));
    end
    xlim([t(1), t(end)]);
    xlabel(str_xlabel);
    
    trace = obj.C(ind(m), :)*max(obj.A(:, ind(m)));
    
    % adjust threshold for peak detection to show only largest events
    std_thr = 6;
    finish = false;
    while true
        eventTimes = getPeaks(trace, std_thr);
        eventTimes = eventTimes{1};
        if finish
            break;
        elseif numel(eventTimes) > 10
            std_thr = std_thr + 1;
        elseif numel(eventTimes) < 2
            std_thr = std_thr - 1;
            finish = true;
        else
            break
        end
    end
    
    %% save images
    if save_img
        drawnow();
        saveas(gcf, sprintf('neuron_%d.png', ind(m)));
        m = m+1;
    else
        fprintf('Neuron %d, keep(k, default)/delete(d)/split(s)/trim(t)\n\t/trim cancel(tc)/delete all(da)/backward(b)/end(e)/show movie(m):    ', ind(m));
        
        set(h, 'CurrentCharacter', 'k');
        waitforbuttonpress();
        temp = get(h, 'CurrentCharacter');
        if temp=='d'
            ind_del(m) = true;
            m = m+1;
        elseif strcmpi(temp, 'b')
            m = m-1;
        elseif strcmpi(temp, 'da')
            ind_del(m:end) = true;
            break;
        elseif strcmpi(temp, 'k')
            ind_del(m) = false;
            m= m+1;
        elseif strcmpi(temp, 's')
            try
                subplot(222);
                temp = imfreehand();
                tmp_ind = temp.createMask();
                tmpA = obj.A(:, ind(m));
                obj.A(:, end+1) = tmpA.*tmp_ind(:);
                obj.C(end+1, :) = obj.C(ind(m), :);
                obj.A(:, ind(m)) = tmpA.*(1-tmp_ind(:));
                obj.S(end+1, :) = obj.S(ind(m), :);
                obj.C_raw(end+1, :) = obj.C_raw(ind(m), :);
                obj.P.kernel_pars(end+1, :) = obj.P.kernel_pars(ind(m), :);
                k_ids = obj.P.k_ids;
                obj.ids(end+1) = k_ids+1;   % assign an neuron id
                obj.tags(end+1) = obj.tags(ind(m));
                obj.P.k_ids = k_ids+1;
                fprintf(flog, '\tSplit %d --> %d + %d\n', obj.ids(ind(m)),obj.ids(ind(m)), k_ids);
            catch
                fprintf('the neuron was not split\n');
            end
        elseif strcmpi(temp, 't')
            try
                subplot(222);
                temp = imfreehand();
                tmp_ind = temp.createMask();
                Amask(:, ind(m)) = tmp_ind(:);
                ind_trim(m) = true;
            catch
                fprintf('the neuron was not trimmed\n');
            end
        elseif strcmpi(temp, 'tc')
            Amask(:, ind(m)) = (obj.A(:, ind(m)) > 0);
            ind_trim(m) = false;
        elseif strcmpi(temp, 'e')
            break;
        elseif strcmpi(temp, 'm')
            if isempty(eventTimes)
                eventTime = 100;
            else
                if eventIdx > numel(eventTimes)
                    eventIdx = 1;
                end
                fprintf('Showing event %d out of %d\n', eventIdx, numel(eventTimes))
                eventTime = eventTimes(eventIdx);
            end
            temporalWindow = 50;
            cutout_start = max(1, eventTime - temporalWindow/2);
            cutout_end = min(eventTime + temporalWindow/2, size(obj.C, 2));
            Ypatch = obj.load_patch_data([], [cutout_start, cutout_end]);
            playEventMovie(Ypatch, ind(m), trace(cutout_start:cutout_end), ...
                ctr, outlines, ind_del);
            eventIdx = eventIdx + 1;

        elseif ~isnan(str2double(temp))
            m = m + floor(str2double(temp));
            m = max(m, 1);
            m = min(m, length(ind));
            fprintf('jump to neuron %d / %d\n', m, length(ind));
        else
            %m = m+1;
        end
    end
end
if save_img
    cd(cur_cd);
else
    if ~isempty(ind(ind_trim))
        obj.A(:, ind(ind_trim)) = obj.A(:,ind(ind_trim)).*Amask(:, ind(ind_trim));
        try
            fprintf(flog, '\n\tFollowing neurons were trimmed:\n');
            ids_trimmed = ind(ind_trim);
            for m=1:length(ids_trimmed)
                fprintf(flog, '%2d, ', ids_trimmed(m));
            end
            fprintf(flog, '\n');
        end
    end
    
    if ~isempty(ind(ind_del))
        try
            fprintf(flog, '\tDeleting manually selected neurons:\n');
        end
        obj.delete(ind(ind_del));
    end
    %     obj.Coor = obj.get_contours(0.9);
    
    
    return;
end
try
    fprintf(flog, '[%s]\b', get_minute());
    fprintf(flog, 'Finished the manual intervention.\n');
    fprintf(flog, '[%s]\b', get_minute());
    if obj.options.save_intermediate
        manual_intervention.after = obj.obj2struct(); %#ok<STRNU>
        tmp_str = get_date();
        tmp_str=strrep(tmp_str, '-', '_');
        eval(sprintf('log_data.manual_%s = manual_intervention;', tmp_str));
        
        fprintf(flog, '\tThe results were saved as intermediate_results.manual%s\n\n', tmp_str);
    end
    fclose(flog);
end
end

