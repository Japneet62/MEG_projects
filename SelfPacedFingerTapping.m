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

%% Set your path to the data
%==========================================================================
filename = 'task_finger.fif';
datapath = fullfile('/Users/japneetbhatia/Desktop/MEG/data/Finger',filename);

%% Computation of Evoked Fields
%==========================================================================

prestim  = 0.1; % prestimulus interval 100 ms
poststim = 0.6; % posttimulus interval 600 ms
bp_freq  = [1,45]; % bandpass filter frequencies 1-45 Hz

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

% Check event marker stream to see button presses
%------------------------------------------------
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
xlim([60,70]) % random time window
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
% Computation of average over all trials. This leads to the Evoked Field.
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

timewin = [0.08,0.2]; % 80-200 ms

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

%% Have a look at the spectrum 
%==========================================================================

% Check Intrinsic rhythm of button presses by plotting InterStimulus
% Interval (ISI)
%-------------------------------------------------------------------
hdr    = ft_read_header(datapath,'checkmaxfilter','no'); % load header
events = ft_read_event(datapath,'checkmaxfilter','no'); % load events

smp = [events.sample]; % event maerker samples
typ = {events.type}; % event marker types
val = [events.value]; % event marker values

% Computation of ISI
%-------------------
sample = smp(strcmp(typ,'STI101')); % keep samples of STI101 channel
ISI_s  = diff(sample)/hdr.Fs; % in s % Get ISI by taking difference between consecutive samples
ISI_Hz = 1./ISI_s; % frequency corresponding to ISI

% Plot ISI as histogram
%----------------------
figure
subplot(1,2,1)
histogram(ISI_s)
xlabel('ISI / s')
subplot(1,2,2)
histogram(ISI_Hz)
xlabel('ISI / Hz')
sgtitle('Interstimulus Interval')

% Plot ISI over time
%-------------------
time_vec = smp(strcmp(typ,'STI101'))./hdr.Fs;
figure
plot(time_vec(1:end-1),ISI_Hz,'.');
xlabel('t / s')
ylabel('ISI / Hz')
ylim([0,2]) % adjust ylim if necessary
title('Interstimulus Interval')
grid on

% Check whether the intrinsic rhythm is visible in the spectrum of the MEG
% signals
%-------------------------------------------------------------------------
% Adjust the time window of the fft so that it fits the time window when
% the button was pressed at a sepecific frequency

% Procedure
%----------
% First a time window is selected, then the selected time window is cutted
% into 20s epochs and finally, the average spectrum over all epochs is
% calculated.

cfg           = [];
cfg.latency   = [150,300]; % Adjust time window for spectrum analysis
data_selected = ft_selectdata(cfg,data);

cfg          = [];
cfg.length   = 20; % the data is cutted in trials of 10s length
cfg.overlap  = 0; % there is no overlap between trials
data_epoched = ft_redefinetrial(cfg, data_selected);

% Spectrum magnetometers
cfg          = [];
cfg.output   = 'pow'; % return the power-spectra
cfg.method   = 'mtmfft'; % implements multitaper frequency transformation
cfg.taper    = 'hanning'; % hanning window
cfg.foilim   = [0.1,20]; % Adjust frequency range
cfg.channel  = 'megmag';
spectrum_mag = ft_freqanalysis(cfg, data_epoched);

% Spectrum gradiometers
cfg           = [];
cfg.output    = 'pow'; 
cfg.method    = 'mtmfft'; 
cfg.taper     = 'hanning'; 
cfg.foilim    = [0.1,20]; 
cfg.channel   = 'megplanar';
spectrum_grad = ft_freqanalysis(cfg, data_epoched);

% Plot spectrum
figure
subplot(2,1,1)
semilogy(spectrum_mag.freq, spectrum_mag.powspctrm)
xlim([0.1,15])
xlabel('Frequency / Hz');
ylabel('absolute power');
title('Magnetometers')
subplot(2,1,2)
semilogy(spectrum_grad.freq, spectrum_grad.powspctrm)
xlim([0.1,15])
xlabel('Frequency / Hz');
ylabel('absolute power');
title('Gradiometers')

