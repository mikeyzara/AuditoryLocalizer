%% INITIALISE
% Clear out the workspace and generate an LSL stream to send markers
clear all;

addpath('Matlab_lsl_scripts') % Need this folder to create LSL stream

lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'Narrowband_Stream','Markers',1,0,'cf_int32','narrowband1');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

fprintf('Set up LSL connection on OxySoft. Press any button to continue... '); % Input from experimenter needed -- is everything good to go?
pause;                               % Press a button on keyboard to send a trigger when ready!
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
fprintf('What is the desired direction? (1 = up; 2 = down)\n');
while ~isscalar(direction) || (direction < 1) || (direction > 2) || (direction ~= round(direction))
    direction = input('> ');
end

% n = 1;
% while exist(sprintf('thresholds_%04d.mat', n), 'file')
%   n = n+1;
% end
% load(sprintf('thresholds-%04d.mat', n-1));
% fprintf('Using thresholds #%04d.\n', n-1);
load('thresholds_1.mat');

%% Adjusting the loudness
[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);
%  exp(frequencies.*log(2)).*1000

%% Generate envelope of sequence
envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 77), ones(1, 12)/12);

%% Order of tones played
switch direction
    case 1
        ordering = [4, 12, 7, 2, 10, 5, 8, 3, 11, 6, 1, 9];
    case 2
        ordering = [9, 1, 6, 11, 3, 8, 5, 10, 2, 7, 12, 4];
end
clear playsnd;

%% Generate sequence and play audio
for c = 1:36 % Thirty-six blocks; present each of the 12 tones 3 times
    wave = zeros(88*4410, 2); %Allocate memory for sequence
    if (ordering(mod(c-1, 12)+1) > 0) %A remnant of the past; this was to indicate silent baseline condition
        for n = 1:88 %For the 8.8 seconds
            f = round(6*(ordering(mod(c-1, 12)+1)-rand)); %Select the frequency within a specific bin
            wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+thresholds(f+1, :)+offset)); %generate the sequence of tones
        end
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
    %% Play stimuli diotically
    sound(wave, 44100); %Play the sequence
    outlet.push_sample(ordering(mod(c-1, 12)+1)); %Push a marker indicating the start of stimuli
    fprintf('Playing block #%d (of 36)\n', c);
    if (c==12)
        outlet.push_sample(33); %Push a marker indicating the start of silent block
        pause(15+size(wave,1)/44100);
        fprintf('Experiment done.');
    end
end
