%% INITIALISE

clear all;

DCT_FUNCTIONS = { % antiderivatives of DCT functions mapping [0,1] -> [0,1]
    @(x) x,
    @(x) x+sin(pi*x)/pi,
    @(x) x-sin(pi*x)/pi,
    @(x) x+sin(2*pi*x)/2/pi,
    @(x) x-sin(2*pi*x)/2/pi,
    @(x) x+sin(3*pi*x)/3/pi,
    @(x) x-sin(3*pi*x)/3/pi
    };

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
fprintf('Which ear do we play the audio to first? (1 = left; 2 = right)\n');
while ~isscalar(direction) || (direction < 1) || (direction > 2) || (direction ~= round(direction))
    direction = input('> ');
end

order = [];
fprintf('Which order will be played to the first ear? (1 = order1; 2 = order2)\n Note: The opposite order will be played to the other ear\n');
while ~isscalar(order) || (order < 1) || (order > 2) || (order ~= round(order))
    order = input('> ');
end

% n = 0;
% while exist(sprintf('thresholds-%04d.mat', n), 'file')
%   n = n+1;
% end
% load(sprintf('thresholds-%04d.mat', n-1));
% fprintf('Using thresholds #%04d.\n', n-1);

load('thresholds_1.mat');

[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);
envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 77), ones(1, 12)/12);

ordering1 = [1, 7, 3, 4, 7, 2, 0, 1, 3, 6, 4, 5, 2, 1, 0, 4, 6, 3, 0, 1, 5, 0, 7, 5, 6, 2];
ordering2 = [2, 6, 5, 7, 0, 5, 1, 0, 3, 6, 4, 0, 1, 2, 5, 4, 6, 3, 1, 0, 2, 7, 4, 3, 7, 1];

clear playsnd;

for c = 1:26 % Twenty-six blocks
    o1_wave = zeros(88*4410, 2);
    o2_wave = zeros(88*4410, 2);
    if (ordering1(c) > 0)
        for n = 1:88
            f1 = find([DCT_FUNCTIONS{ordering1(c)}((1:2:143)/144) > rand, true], 1)-1;
            o1_wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f1-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f1+1)*fade(n)+thresholds(f1+1, :)+offset));
        end
    end
    if (ordering2(c) > 0)
        for n = 1:88
            f2 = find([DCT_FUNCTIONS{ordering2(c)}((1:2:143)/144) > rand, true], 1)-1;
            o2_wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f2-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f2+1)*fade(n)+thresholds(f2+1, :)+offset));
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
    fprintf('Playing block #%d (of 26)\n', c);
    switch direction
        case 1 %Left ear plays first
            if order == 1 %Order 1 played to the left ear; Order 2 played to the right ear
                left = [o1_wave(:,1) zeros(size(o1_wave,1),1)];
                sound(left,44100);
                pause((size(left,1)/44100)+1); %Pause to let the first sound play before playing the next sound
                right = [zeros(size(o2_wave,1),1) o2_wave(:,2)];
                sound(right,44100);
            else %Order 2 played to the left ear; Order 1 played to the right ear
                left = [o2_wave(:,1) zeros(size(o2_wave,1),1)];
                sound(left,44100);
                pause((size(left,1)/44100)+1);%Pause to let the first sound play before playing the next sound
                right = [zeros(size(o1_wave,1),1) o1_wave(:,2)];
                sound(right,44100);
            end
        case 2 %Right ear plays first
            if order == 1 %Order 1 played to the right ear; Order 2 played to the left ear
                right = [zeros(size(o1_wave,1),1) o1_wave(:,2)];
                sound(right,44100);
                pause((size(left,1)/44100)+1);%Pause to let the first sound play before playing the next sound
                left = [o2_wave(:,1) zeros(size(o2_wave,1),1)];
                sound(left,44100);
            else %Order 2 played to the right ear; Order 1 played to the left ear
                right = [zeros(size(o2_wave,1),1) o2_wave(:,2)];
                sound(right,44100);
                pause((size(left,1)/44100)+1);%Pause to let the first sound play before playing the next sound
                left = [o1_wave(:,1) zeros(size(o1_wave,1),1)];
                sound(left,44100);
            end
    end
end
