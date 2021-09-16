%% INITIALISE

clear all;

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
fprintf('What is the desired direction? (1 = up; 2 = down)\n');
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

[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);
envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 77), ones(1, 12)/12);

switch direction
  case 1
    ordering = [1, 7, 3, 4, 7, 2, 0, 1, 3, 6, 4, 5, 2, 1, 0, 4, 6, 3, 0, 1, 5, 0, 7, 5, 6, 2];
  case 2
    ordering = [2, 6, 5, 7, 0, 5, 1, 0, 3, 6, 4, 0, 1, 2, 5, 4, 6, 3, 1, 0, 2, 7, 4, 3, 7, 1];
end
clear playsnd;

for c = 1:26 % Twenty-six blocks
  wave = zeros(88*4410, 2);
  if (ordering(c) > 0)
    for n = 1:88
      f = find([DCT_FUNCTIONS{1}((1:2:143)/144) > rand, true], 1)-1;
      wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+thresholds(f+1, :)+offset));
    end
  end
  if (c == 1)
    fprintf('Waiting for trigger ... ');
    pause;
    tic;
    fprintf('received!\n');
  end
  pause((c*6-4)*2.2-toc-delay);
  sound(wave,44100)
  fprintf('Playing block #%d (of 26)\n', c);
end
