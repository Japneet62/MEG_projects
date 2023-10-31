close all
clear all
clc

%% Initialize FielTrip 
%==========================================================================
% In case you havent installed FielTrip with the MATLAB startup.m file and 
% it is therefore not launched automatically during MATALB startup, you
% need to execute the following lines

% Set your path to FieldTrip
path_to_fieldtrip = '/Users/japneetbhatia/Desktop/MEG/meg_course_2023/fieldtrip-20230215';
addpath(path_to_fieldtrip)
ft_defaults

%% Set your paths to the data
%==========================================================================
datapath = cell(1,6);
% Adjust the rootpath to your data
rootpath = '/Users/japneetbhatia/Desktop/MEG/data/OnGo';

% artifacts
filename    = 'task_ongo_artifacts.fif';
datapath{1} = fullfile(rootpath,filename);

% artifacts random
filename    = 'task_ongo_artifacts_random.fif';
datapath{2} = fullfile(rootpath,filename);

% pre, eyes open
filename    = 'task_ongo_rest_open_pre.fif';
datapath{3} = fullfile(rootpath,filename);

% pre, eyes closed
filename    = 'task_ongo_rest_closed_pre.fif';
datapath{4} = fullfile(rootpath,filename);

% post, eyes open
filename    = 'task_ongo_rest_open_post.fif';
datapath{5} = fullfile(rootpath,filename);

% post, eyes closed
filename    = 'task_ongo_rest_closed_post.fif';
datapath{6} = fullfile(rootpath,filename);

%% Browse through artifact data
%==========================================================================

% The button presses are marked as vertical lines in the databrowser so
% that you can easily identify them.
% The scaling can be adjusted in the GUI, so play around with it.
% Uncomment datapath1 or datapath2 to plot the corresponding artifact data.

% Magnetometers 
cfg                 = [];
% cfg.dataset         = datapath{1}; 
cfg.dataset         = datapath{2};
cfg.viewmode        = 'butterfly'; % vertical
cfg.channel         = 'megmag'; % magnetometers
cfg.blocksize       = 20; % 10s
% cfg.ylim            =[-10^-10,10^-10]; % optinal scaling
cfg.preproc.detrend = 'yes'; % remove linear trend from data
ft_databrowser(cfg)

% Gradiometers
cfg                 = [];
% cfg.dataset         = datapath{1};
cfg.dataset         = datapath{2};
cfg.viewmode        = 'butterfly'; % vertical
cfg.channel         = 'megplanar'; 
cfg.blocksize       = 20;
cfg.preproc.detrend = 'yes'; % remove linear trend from data
ft_databrowser(cfg)

%% Computation of spectra for resting state recordings
%==========================================================================
% The spectra of all four resting state conditions are calculated with a
% for-loop. The data four each condition is loaded, cut into 10s epochs
% and the spectra over all epochs were averaged to get a smoother estimate.

% loop over all four conditions
%------------------------------ 
% 1. pre, eyes open
% 2. pre, eyes closed
% 3. post, eyes open
% 4. post, eyes closed

conditions = {'pre, eyes open',...
              'pre, eyes closed',...
              'post, eyes open',...
              'post, eyes closed'};

spectrum_mag  = cell(1,4);
spectrum_grad = cell(1,4);

% loop over conditions
for i=1:4
    cfg         = [];
    cfg.dataset = datapath{i+2}; 
    cfg.channel = 'meg'; % event marker channel
    data        = ft_preprocessing(cfg);

    cfg          = [];
    cfg.length   = 10; % the data is cutted in trials of 10s length
    cfg.overlap  = 0; % there is no overlap between trials
    data_epoched = ft_redefinetrial(cfg, data);

    % Spectrum magnetometers
    cfg             = [];
    cfg.output      = 'pow'; % return the power-spectra
    cfg.method      = 'mtmfft'; % implements multitaper frequency transformation
    cfg.taper       = 'hanning'; % hanning window
    cfg.foilim      = [0.1,150]; % Adjust frequency range
    cfg.channel     = 'megmag';
    spectrum_mag{i} = ft_freqanalysis(cfg, data_epoched);

    % Spectrum gradiometers
    cfg              = [];
    cfg.output       = 'pow'; 
    cfg.method       = 'mtmfft'; 
    cfg.taper        = 'hanning'; 
    cfg.foilim       = [0.1,150]; 
    cfg.channel      = 'megplanar';
    spectrum_grad{i} = ft_freqanalysis(cfg, data_epoched);
end

% Plot all spectra
%-----------------
for i=1:4
    figure
    subplot(2,1,1)
    semilogy(spectrum_mag{i}.freq, spectrum_mag{i}.powspctrm)
    xlim([0.1,40])
    xlabel('Frequency / Hz');
    ylabel('absolute power');
    title('Magnetometers')
    subplot(2,1,2)
    semilogy(spectrum_grad{i}.freq, spectrum_grad{i}.powspctrm)
    xlim([0.1,40])
    xlabel('Frequency / Hz');
    ylabel('absolute power');
    title('Gradiometers')
    sgtitle(conditions{i})
end

%% Compute mean over all channels for easier visualization
%---------------------------------------------------------
spectrum_mag_avg  = cell(1,4);
spectrum_grad_avg = cell(1,4);
for i=1:4
    spectrum_mag_avg{i}  = mean(spectrum_mag{i}.powspctrm,1);
    spectrum_grad_avg{i} = mean(spectrum_grad{i}.powspctrm,1);
end

% Plot Contrast Conditions
%-------------------------
% 1. Contrast: 
% Pre: eyes closed - eyes open -> Cond. 2 - Cond. 1
% 2. Contrast: 
% Post: eyes closed - eyes open -> Cond. 4 - Cond. 3
% 3. Contrast: 
% Post, eyes open - Pre, eyes open -> Cond. 3 - Cond. 1
% 4. Contrast: 
% Post, eyes closed - Pre, eyes closed -> Cond. 4 - Cond. 2

contrasts = {'Pre: eyes closed - eyes open',...
             'Post: eyes closed - eyes open',...
             'Post, eyes open - Pre, eyes open',...
             'Post, eyes closed - Pre, eyes closed'};
% corresponding contrast indices
idx = [2,1;
       4,3;
       3,1;
       4,2];

% Plot all spectra
%-----------------
for i=1:4
    % magnetometers
    figure
    subplot(2,1,1)
    semilogy(spectrum_mag{i}.freq, spectrum_mag_avg{idx(i,1)})
    hold on
    semilogy(spectrum_mag{i}.freq, spectrum_mag_avg{idx(i,2)})
    xlim([0.1,40])
    xlabel('Frequency / Hz');
    ylabel('absolute power');
    title('Gradiometers')
    sgtitle(contrasts{i})
    legend(conditions{idx(i,1)},conditions{idx(i,2)})

    % gradiometers
    subplot(2,1,2)
    semilogy(spectrum_grad{i}.freq, spectrum_grad_avg{idx(i,1)})
    hold on
    semilogy(spectrum_grad{i}.freq, spectrum_grad_avg{idx(i,2)})
    xlim([0.1,40])
    xlabel('Frequency / Hz');
    ylabel('absolute power');
    title('Gradiometers')
    sgtitle(contrasts{i})
    legend(conditions{idx(i,1)},conditions{idx(i,2)})
end

