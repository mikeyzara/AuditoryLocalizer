%%%%       Read from Enobio LSL Markers       %%%%

% The stream_name must be the same as in NIC/COREGUI.
% The streams vector gathers all the streams available.
% If the NIC stream is inside this vector, the element index is saved in the index variable.
% The stream inlet attempts to connect to the NIC stream.
% If the stream has not been found within the available streams, the scripts raises an error and stops.
% If not, the script starts retrieving data from the NIC stream.


lib = lsl_loadlib();
outletName='NIC';
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','Markers'); 
end

index=-1;
for r=1:length(result)
    if (strcmp(name(result{r}),outletName)==1)
        index=r;
        disp('NIC stream available')
    end
end

if (index == -1)
    disp('Error: NIC stream not available \n');
    return;
end

disp('Connecting to NIC stream...');
inlet = lsl_inlet(result{index});

while true
    [sample,timestamp] = inlet.pull_sample();
    if not(isempty(sample))
        fprintf('Timestamp:\t %.5f\n',timestamp);
        fprintf('Sample:\t %.2f\n\n',sample);
    end
end