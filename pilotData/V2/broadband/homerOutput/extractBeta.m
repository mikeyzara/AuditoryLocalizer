clear all
%% Extract the beta weights from groupResults.mat
load groupResults.mat %Load the .mat file into the workspace
% We'll need to load in the results for each participant. More details can
% be found in this thread: https://openfnirs.org/community/homer3-forum/extracting-beta-weights-after-glm/
numPID = size(group.subjs,2);
for i = 1:numPID % Loop through all participants in this study
    group(1).subjs(i).runs(1).Load;
    %     beta{i} = group.subjs(i).runs.procStream.output.misc.beta; % The indexing required to access beta weights
    beta = group.subjs(i).runs.procStream.output.misc.beta{1}; % The indexing required to access beta weights
    
    % beta is a 4D matrix. In our case, it is size [10 2 22 4], which
    % corresponds to:
    % [# of basis functions X # of Hb Species X # of channels X # of conditions]
    
    % For the output, we want the mean beta value for each channel for both
    % Hb species per condition
    meanBeta = mean(beta,1); % Calculate the mean beta value -- operates on the first dimension (i.e. average of basis function betas)
    betaOutput{i,1} = squeeze(meanBeta(:,:,:,2))'; %condition: LSL1 -- will only take condition '2', which corresponds to LSL1
    betaOutput{i,2} = squeeze(meanBeta(:,:,:,3))'; %condition: LSL2 -- will only take condition '3', which corresponds to LSL2
    
    % Note: betaOutput is a cell of size 15 x 2 (# participants x # conditions)
    %       Each cell will contain a matrix of size 22 x 2 (# channels x # Hb Species)
    %       - The channel list will be extracted in the code below.
    %       - Hb Species: column1 = HbO, column2 = HbR
    
    % Get the initals/PID
    pid{i,1} = group.subjs(i).name(1:2);
end
%% Get the optode channel list
% Create a matrix that indicates the Source-Detector pairing
measList = group.subjs(i).runs.procStream.output.dc.measurementList(1:3:end); %The measurement list
chList = zeros(size(measList,2),2); %Allocate some space for the measurement list
for j = 1:size(measList,2)
    chList(j,:) = [measList(j).sourceIndex measList(j).detectorIndex]; %Source-Detector pairs
    chLabels{j,1} = ['S' num2str(chList(j,1)) '-D' num2str(chList(j,2))];
end

%% Generate an output file
% In this section we format the data so we can output for statistical
% analysis. Each participant will have 44 rows associated with their data
% (22 channels with their associated beta values x 2 conditions). For
% formatting purposes, we'll make repetitions of the different headers.

% Heading: Condition
LSL1 = repmat({'left'},size(chLabels,1),1); % Repeat 'Left' 22 times
LSL2 = repmat({'right'},size(chLabels,1),1); % Repeat 'Right' 22 times
Cond = [LSL1; LSL2]; % Concatenate to get a cell matrix 'Cond' of size 44x1

% Heading: Channels
Ch = repmat(chLabels,2,1); %Repeat channel list twice (22 channels x 2 = 44 rows)

T = cell2table(cell(0,5), 'VariableNames', {'PID','Cond','Ch','HbO_beta','HbR_beta'}); %Initialize a table
for k = 1:size(betaOutput,1)
    % Heading: PID
    PID = repmat(pid(k),size(Cond,1),1); %Repeat the PID 44 times)
    
    % Heading: HbO_Beta & HbR_Beta
    %   The first column of betaOutput is the data for LSL1 (i.e. left
    %   presentation first). The second column is the data for LSL2 (i.e.
    %   right presentation first). For both Hb species, we concatenate LSL1
    %   and LSL2 vertically (22 beta values associated with their channels
    %   x 2 conditions = 44 rows)
    HbO_beta = [betaOutput{k,1}(:,1); betaOutput{k,2}(:,1)]; 
    HbR_beta = [betaOutput{k,1}(:,2); betaOutput{k,2}(:,2)];
    
    temp = table(PID, Cond, Ch, HbO_beta, HbR_beta); %Create a temporary table to store data
    T = [T;temp]; % Grow the table when each participant's data has been formatted
end

writetable(T,'AuditoryLocalizer_Broadband_defaultnewGLM.csv','Delimiter',',','WriteRowNames',true); 

