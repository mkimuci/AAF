% Main script for exporting differential plots
dataDir = 'C:\Users\Public\Documents\experiments\F0vsF1\acousticdata';

% List of subject IDs
subjectIDs = [101, 103, 104, 105, 106, 107, 108, 109, 111, 112, 117, 118, 119, 122, 123];
% subjectIDs = [111];

% Output directory for differential plots
outputDir = fullfile(dataDir, 'differential_plots');
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
    fig = figure('Visible', 'off'); % Create an off-screen figure
    set(gcf, 'PaperUnits', 'inches');
    x_width = 9; y_width = 9; 
    set(gcf, 'PaperPosition', [0 0 x_width y_width]);
    
    % Plot differential data
    plot_subject_differential(subjectID, formantBins, pitchBins); % Add plots to the figure
    
    % Ensure proper rendering
    drawnow;
    
    % Export the plot to a PNG file
    outputFile = fullfile(outputDir, sprintf('Diff_Subject_%s.png', subjectID));
    print(fig, outputFile, '-dpng', '-r300'); % Save as PNG with 300 DPI
    
    % Close the figure after saving
    close(fig);
    
    fprintf('Exported differential plot for Subject ID %s to %s\n', subjectID, outputFile);
end

disp('All differential plots exported successfully.');
