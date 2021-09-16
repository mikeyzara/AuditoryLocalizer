%% INITIALISE

clear all;

tic;
wavplay(zeros(110*4410, 2), 44100);
delay = toc;
fprintf('Taking into account a %d ms soundcard delay.\n', round(delay*1000));

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


[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);
%  exp(frequencies.*log(2)).*1000

envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 77), ones(1, 12)/12);
switch direction
    case 1
        ordering = [4, 12, 7, 2, 10, 5, 0, 8, 3, 11, 6, 1, 9];
    case 2
        ordering = [9, 1, 6, 11, 3, 8, 0, 5, 10, 2, 7, 12, 4];
end
clear playsnd;

for c = 1:26 % Twenty-six blocks
    wave = zeros(88*4410, 2);
    if (ordering(mod(c-1, 13)+1) > 0)
        for n = 1:88
            f = round(6*(ordering(mod(c-1, 13)+1)-rand));
            wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+thresholds(f+1, :)+offset)); %original
        end
    end
    if (c == 1)
        fprintf('Waiting for trigger ... ');
        pause;
        tic;
        fprintf('received!\n');
    end
    pause((c*6-4)*2.2-toc-delay);
    
    %% Play stimuli monotically
%     left = [wave(:,1) zeros(size(wave,1),1)];
%     right = [zeros(size(wave,1),1) wave(:,2)];
%     sound(left,44100);
%     sound(right,44100);
      player = audioplayer(wave, 44100);
      play(player); %Original
    fprintf('Playing block #%d (of 26)\n', c);
end
