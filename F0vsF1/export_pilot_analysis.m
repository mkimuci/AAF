% Main script for exporting plots
dataDir = 'C:\Users\Public\Documents\experiments\F0vsF1\acousticdata';

% List of subject IDs
% subjectIDs = [101, 103, 104, 105, 106, 107, 108, 109, 112, 117, 118, 119, 122, 123];
subjectIDs = [111];

% Output directory for plots
outputDir = fullfile(dataDir, 'plots');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% Loop through each subject ID
for i = 1:length(subjectIDs)
    subjectID = num2str(subjectIDs(i));
    subjectDir = fullfile(dataDir, subjectID);
    
    % Check if subject directory exists
    if ~isfolder(subjectDir)
        fprintf('Subject ID %s directory not found. Skipping...\n', subjectID);
        continue;
    end
    
    % Process subject data
    [formantBins, pitchBins] = process_subject_data(subjectID, dataDir);
    
    % Create a plot for the subject
    figure('Visible', 'off'); % Remove explicit size here
    plot_subject_data(subjectID, formantBins, pitchBins); % Plot data
    
    % Set the size of the figure for exporting
    set(gcf, 'PaperUnits', 'inches');
    x_width = 5; y_width = 9;
    set(gcf, 'PaperPosition', [0 0 x_width y_width]);
    
    % Export plot to PNG
    outputFile = fullfile(outputDir, sprintf('Subject_%s.png', subjectID));
    print(gcf, '-dpng', '-r300', outputFile); % Save with specified resolution
    close(gcf); % Close the figure after saving
    
    fprintf('Exported plot for Subject ID %s to %s\n', subjectID, outputFile);
end

disp('All plots exported successfully.');
