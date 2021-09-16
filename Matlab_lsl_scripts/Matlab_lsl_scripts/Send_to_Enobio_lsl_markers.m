%%%%       Send to enobio LSL markers      %%%%
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MyMarkerStream3','Markers',1,0,'cf_int32','myuniquesourceid23443');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

disp('Sending data...');
while true
    pause(rand()*3);
    mrk=111;
    outlet.push_sample(mrk);   
    disp(['Now sending: ' int2str(mrk)]);
end