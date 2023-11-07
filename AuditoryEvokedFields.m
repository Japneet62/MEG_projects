close all
clear all
clc

%% Initialize FieldTrip 
%==========================================================================
% In case you havent installed FielTrip with the MATLAB startup.m file and 
% it is therefore not launched automatically during MATALB startup, you
% need to execute the following lines

% Set your path to FieldTrip
path_to_fieldtrip = '/Users/japneetbhatia/Desktop/MEG/meg_course_2023/fieldtrip-20230215';
addpath(path_to_fieldtrip)
ft_defaults

%% Switch experiment
%==========================================================================
% Uncomment the AEF type that you want to analyze
% AEF_type = 'SLAEF'; % Short latency auditory evoked fields
AEF_type = 'LLAEF'; % Long latency auditory evoked fields

% Specific settings for AEF types
switch AEF_type
    case 'SLAEF'
        filename = 'task_audio_fast.fif';
        prestim  = 0.01; % prestimulus interval 10 ms
        poststim = 0.05; % poststimulus interval 50ms
        bp_freq  = [180,1000]; % bandpass filter frequencies 180-1000 Hz
        timewin  = [0.005 0.02]; % time window for topoplot 5-20ms
    case 'LLAEF'
        filename = 'task_audio_slow.fif';
        prestim  = 0.1;
        poststim = 0.8;
        bp_freq  = [1,45];
        timewin  = [0.1 0.2];
end

% Set your path to the data
datapath = fullfile('C:\Users\tillhabersetzer\Nextcloud\meg_course_2023\Analysis\AuditoryEvokedFields\rawdata\sub-01\meg',filename);

%% Computation of Auditory Evoked Fields
%==========================================================================

% Define trials
%--------------
% First the time windows for the trials (a.k.a. epochs) are defined
cfg                     = [];
cfg.dataset             = datapath; % path to dataset
cfg.trialfun            = 'ft_trialfun_general'; % fieldtrip function for trial handling
cfg.trialdef.eventtype  = 'STI101'; % event marker channel
cfg.trialdef.eventvalue = 1; % eventmarker value
cfg.trialdef.prestim    = prestim;                  
cfg.trialdef.poststim   = poststim;                  
cfg                     = ft_definetrial(cfg);
trl                     = cfg.trl; % trial definition

% Optionally: Check event marker stream
%--------------------------------------
cfg         = [];
cfg.dataset = datapath; 
cfg.channel = 'STI101'; % event marker channel
events      = ft_preprocessing(cfg);

event_stream = events.trial{1};
time         = events.time{1};

% Plot event marker stream
figure
plot(time,event_stream)
xlabel('t / s')
ylabel('event marker value')
xlim([60,63]) % random time window
ylim([0,3])

% Load and filter continuous data to avoid edge artifacts
%--------------------------------------------------------
cfg              = [];
cfg.dataset      = datapath;
cfg.channel      = 'meg'; % Load MEG channels 
cfg.continuous   = 'yes'; % data is still continuous, not yet epoched
cfg.bpfilter     = 'yes'; % apply bandpass filter
cfg.bpfreq       = bp_freq; % bandpass frequencies
cfg.bpfiltord    = 3; % set bandpass filter order
cfg.coilaccuracy = 0; % ensure that sensors are expressed in SI units
data             = ft_preprocessing(cfg); 
        
% Epoch data
%-----------
% the data is chopped into trials/ epochs with the previously calculated
% trl-intervals
cfg     = [];
cfg.trl = trl;  
epoched = ft_redefinetrial(cfg,data); 

% Apply semi automatic artifact rejection
%----------------------------------------
% Rejection of noisy trials; this is done separately for magnetometers and
% gradiometers. You may want to check out: https://www.fieldtriptoolbox.org/tutorial/visual_artifact_rejection/

% Magnetometers
cfg             = [];
cfg.metric      = 'zvalue'; % use z-value for thresholding
cfg.channel     = 'megmag'; % only check magnetometers
cfg.keepchannel = 'yes';  % This keeps the channels that are not displayed in the data
epoched         = ft_rejectvisual(cfg,epoched);

% Gradiometers
cfg.channel     = 'megplanar';
epoched         = ft_rejectvisual(cfg,epoched);

% Demean trials
%--------------
% Apply baseline correction
cfg                = [];
cfg.demean         = 'yes';
cfg.baselinewindow = [-prestim 0]; % baseline time window
epoched            = ft_preprocessing(cfg,epoched);  

% Check number of left over trials
N_trials = length(epoched.trial);

% Timelockanalysis
%-----------------
% Computation of average over all trials. This gives you the Auditory 
% Evoked Field (AEF)
cfg = [];
avg = ft_timelockanalysis(cfg, epoched);

%% Visualize the results
%==========================================================================

% Plot all channels in a topographical layout
%--------------------------------------------
% You can also open a separate window for a channel by drawing a square 
% around it with the mouse

% Magnetometers
%--------------
cfg            = [];
cfg.showlabels = 'yes'; % show channel labels
cfg.fontsize   = 6;
cfg.layout     = 'neuromag306mag.lay'; % magnetometer layout
ft_multiplotER(cfg, avg);
sgtitle('Magnetometers')

% Gradiometers
%-------------
cfg            = [];
cfg.showlabels = 'yes'; 
cfg.fontsize   = 6;
cfg.layout     = 'neuromag306planar.lay'; % gradiometer layout
ft_multiplotER(cfg, avg);
sgtitle('Gradiometers')

% The planar gradient magnitudes over both directions at each sensor can 
% also be combined into a single positive-valued number
cfg        = [];
cfg.method = 'sum';
avg_cmb    = ft_combineplanar(cfg,avg);

% Combined Gradiometers
%----------------------
cfg            = [];
cfg.showlabels = 'yes'; 
cfg.fontsize   = 6;
cfg.layout     = 'neuromag306cmb.lay'; % gradiometer layout
ft_multiplotER(cfg, avg_cmb);
sgtitle('Combined Gradiometers')

% Make a topoplot
%----------------

% Magnetometers
%--------------
figure
subplot(1,3,1)
cfg        = [];
cfg.xlim   = timewin; % time window of maximum amplitude (N100m, or wave five for ABR)
cfg.layout = 'neuromag306mag.lay';
cfg.figure = 'gcf'; % embeds topoplot in current figure
ft_topoplotER(cfg,avg); 
title('magnetometers')

% Gradiometers
%--------------
subplot(1,3,2)
cfg        = [];
cfg.xlim   = timewin; 
cfg.layout = 'neuromag306planar.lay';
cfg.figure = 'gcf';
ft_topoplotER(cfg,avg); 
title('Gradiometers')

% Combined Gradiometers
%----------------------
subplot(1,3,3)
cfg        = [];
cfg.xlim   = timewin; 
cfg.layout = 'neuromag306cmb.lay';
cfg.figure = 'gcf';
ft_topoplotER(cfg,avg_cmb); 
title('Combined Gradiometers')
