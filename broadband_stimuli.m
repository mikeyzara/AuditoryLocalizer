%% INITIALISE
% Clear out the workspace and generate an LSL stream to send markers
clear all;

addpath('Matlab_lsl_scripts') % Need this folder to create LSL stream

lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'Broadband_Stream','Markers',1,0,'cf_int32','broadband1');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

fprintf('Set up LSL connection on OxySoft. Press any button to continue... \n'); % Input from experimenter needed -- is everything good to go?
pause;                               % Press a button on keyboard to send a trigger when ready!
%% The Sinusoidal distributions described in paper; we want only the first distribution for our stimuli
DCT_FUNCTIONS = { % antiderivatives of DCT functions mapping [0,1] -> [0,1]
    @(x) x,
    %   @(x) x+sin(pi*x)/pi,
    %   @(x) x-sin(pi*x)/pi,
    %   @(x) x+sin(2*pi*x)/2/pi,
    %   @(x) x-sin(2*pi*x)/2/pi,
    %   @(x) x+sin(3*pi*x)/3/pi,
    %   @(x) x-sin(3*pi*x)/3/pi
    };

%% Settings
setting = [];
fprintf('What is the employed amplifier setting? (1-6; recommended: 6)\n');
while ~isscalar(setting) || (setting < 1) || (setting > 6) || (setting ~= round(setting))
    setting = input('> ');
end
offset = [87.6, 27.8, 19.3, 11.3, 5.4, 0.0];
offset = offset(setting);

intensity = [];
fprintf('What is the desired sound intensity [dB SL]? (0-90)\n');
while ~isscalar(intensity) || (intensity < 0) || (intensity > 100)
    intensity = input('> ');
end

direction = [];
fprintf('Which ear is the stimuli played to first? (1 = left; 2 = right)\n');
while ~isscalar(direction) || (direction < 1) || (direction > 2) || (direction ~= round(direction))
    direction = input('> ');
end

% n = 0;
% while exist(sprintf('thresholds-%04d.mat', n), 'file')
%   n = n+1;
% end
% load(sprintf('thresholds-%04d.mat', n-1));
% fprintf('Using thresholds #%04d.\n', n-1);

load('thresholds_1.mat');

%% Adjusting the loudness
[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);

%% Generate envelope of sequence
envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 77), ones(1, 12)/12);

%% Determine ordering based on which ear the stimuli is played to first
switch direction
    case 1 %Left ear played first
        ordering = {[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1]}; %Left ear played first
    case 2 %Right ear played first
        ordering = {[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0],[0 1],[1 0]}; %Right ear played first
end
clear playsnd;

%% Generate sequence and play audio
% Each sequence is 8.8 sec long + 15 sec silent period following
% stimuli presentation = 23.8sec per presentation block
for c = 1:12 % Twelve blocks: (12*23.8sec)/60 = 4.76 mins
    wave = zeros(88*4410, 2); % Allocate memory for sequence
    for n = 1:88 %For each sec in stimuli presentation
        f = find([DCT_FUNCTIONS{1}((1:2:143)/144) > rand, true], 1)-1; % Select a frequency based on flat DCT distribution
%         wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+thresholds(f+1, :)+offset)); % Generate the tone
%         wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+[1 1]+offset)); % Generate the tone
        wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, [spl(f+1) spl(f+1)].*fade(n)+offset)); %generate the sequence of tones
    end
    if (c == 1) %The first trial: need to get 10s baseline measurement first before playing the first stimuli
        fprintf('Waiting for trigger ... '); % Input from experimenter needed -- is everything good to go?
        pause;                               % Press a button on keyboard to send a trigger when ready!
        tic;
        fprintf('received!\n');
        fprintf('Starting baseline measurement...\n'); %Visual cue indicating baseline measurement is in progress
        outlet.push_sample(0); %Push a marker indicating the start of baseline
        pause(10); % 10 seconds
        outlet.push_sample(0); %Push a marker indicating the end of baseline
        fprintf('Done!\n'); %Visual cue indicating baseline measurement has ended
    else %For all other trials
        outlet.push_sample(33); %Push a marker indicating the start of silent block
        pause(15+size(wave,1)/44100); %Wait 15 seconds. Pause is longer because 'sound' function below returns immediately: https://www.mathworks.com/matlabcentral/answers/22809-pause-not-working-properly
    end
    switch direction
        case 1 %Left ear played first
            if mod(c,2) == 1 %The odd numbered presentations
                outlet.push_sample(1); %Push a marker indicating stimuli played to left ear
            else
                outlet.push_sample(2); %Push a marker indicating stimuli played to right ear
            end
        case 2 %Right ear played first
            if mod(c,2) == 1 %The odd numbered presentations
                outlet.push_sample(2); %Push a marker indicating stimuli played to right ear
            else
                outlet.push_sample(1); %Push a marker indicating stimuli played to left ear
            end
    end
    sound(ordering{c}.*wave,44100) % Play the monotic stimuli. Multiplying 'wave' with 'ordering{c}' enables us to play stimuli to only left/right channel
    fprintf('Playing block #%d (of 12)\n', c);
    if (c==12)
        outlet.push_sample(33); %Push a marker indicating the start of silent block
        pause(15+size(wave,1)/44100);
        fprintf('Experiment done.');
    end
end
