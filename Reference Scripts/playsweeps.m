%% INITIALISE

clear all;

tic;
wavplay(zeros(242*4410, 2), 44100, 'async');
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

n = 0;
while exist(sprintf('thresholds-%04d.mat', n), 'file')
  n = n+1;
end
load(sprintf('thresholds-%04d.mat', n-1));
fprintf('Using thresholds #%04d.\n', n-1);

[spl, f] = iso226(intensity);
spl = spl-iso226(0);
spl = interp1(log(f/1000)/log(2), spl, frequencies);
envelope = (1-cos(pi*(0:220)'/220))/2; envelope = [zeros(440, 1); envelope; ones(3088, 1); envelope(end:-1:1); zeros(440, 1)];
fade = conv(ones(1, 231), ones(1, 12)/12);
clear playsnd;

%%
for c = 1:12 % Twelve cycles
  wave = zeros(242*4410, 2);
  for n = 1:242
    switch direction
      case 1
        f = round((n-.5)/242*66+6*rand);
      case 2
        f = round((242.5-n)/242*66+6*rand);
    end
    wave((n-1)*4410+(1:4410), :) = (sin(pi/22.05*exp(log(2)*(f-36)/12)*(1:4410)').*envelope)*exp(log(10)/20*min(0, spl(f+1)*fade(n)+thresholds(f+1, :)+offset));
  end
  if (c == 1)
    fprintf('Waiting for trigger ... ');
    pause;
    tic;
    fprintf('received!\n');
  end
  pause((c*13-12)*2.2-toc-delay);
  wavplay(wave, 44100, 'async');
  fprintf('Playing sweep #%d (of 12)\n', c);
end
