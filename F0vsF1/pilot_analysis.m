% Main script
dataDir = 'C:\Users\Public\Documents\experiments\F0vsF1\acousticdata'; % Replace with your data directory

while true
    % Prompt user for subject ID
    prompt = 'Enter Subject ID (or type "exit" to quit): ';
    subjectID = input(prompt, 's');
    
    % Exit condition
    if strcmpi(subjectID, 'exit')
        disp('Exiting...');
        break;
    end
    
    % Check if subject directory exists
    subjectDir = fullfile(dataDir, subjectID);
    if ~isfolder(subjectDir)
        disp(['Subject ID "' subjectID '" not found. Please try again.']);
        continue;
    end
    
    % Process and plot data for the entered subject ID
    [formantBins, pitchBins] = process_subject_data(subjectID, dataDir);
    plot_subject_data(subjectID, formantBins, pitchBins);
end