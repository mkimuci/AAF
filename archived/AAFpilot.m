function AAFpilot(varargin)

% function AAFpilot 2023 Hickok Lab NSF Experiment 1
% Written by Kourosh Saberi, Oren Poliva, Minkyu Kim

addpath(genpath('C:\audapter'));

global h header bigResults
global photodiode

global sinitials gender

sinitials = 'MK';
gender = 'male';

AAFduration = 1; % Duration of a trial (sec)

if nargin == 0 
    % Create GUI structure
    clc; close all; figure;
    
    % Clear Buffer
    sound(0 * randn(1, 1000), 44100); 
    clear sound;

    sc=get(0,'screensize');
    set(1,'position',sc,'color','w');
    set(1,'menubar','none','numbertitle','off');
    
    h(1)=uicontrol('units','normalized',...   %text box for title
        'style','text','position',[0.18 0.45 0.65 0.25],...
        'background','w','fore','k',...
        'string',{'AAF Experiment 2 (F1):';...
        'You will see a word displayed on the screen.';...
        'Repeat each word SLOWLY and clearly as soon as it is displayed.';...
        'There are 90 total trials.  Each trial will take around 2 or 3 seconds.';...
        'After you repeat the word, the next trial (and word) will automatically appear.'; ...
        'On some trials you will see the letter string ''yyy''.  You should remain silent ';...
        'During that trial and wait for the next trial to appear.'},...
        'fontsize',16);  
    
    % h(2)=uicontrol('units','normalized',...  %edit box for subject initials
    %     'style','edit','position',[0.42 0.65 0.15 0.07],...
    %     'background','w','string','Enter Subject Initials Here','fontsize',12,...
    %     'enable','on');
    
    h(3)=uicontrol('units','normalized',...   %start pushbutton
        'style','push','position',[0.37 0.33 0.25 0.08],...
        'background','w','fore',[0 0.5 0],...
        'string','Click Here to Start Main Experiment','fontsize',16,...
        'callback','AAFpilot(''callstart'')');   
    
    % h(4)=uicontrol('units','normalized',...   %play example of how to say a word (Bear)
    %    'style','push','position',[0.37 0.44 0.25 0.08],...
    %    'background','w','string','Play example word '' BEAR ''','fontsize',16,...
    %    'callback','AAF1_F1(''example1'')',...
    %    'visible','on','fore','b');  
    
    % h(5)=uicontrol('units','normalized',...      %Gender (needed for Audapter calibration)
    %     'style','pop','position',[0.42 0.55 0.15 0.08],...
    %     'background',[1 1 1],'fore',[0 0 0],...
    %     'string','Female|Male','fontsize',14); 
    
    h(6)=uicontrol('units','normalized',...   %text box for displaying target words on each trial
        'style','text','position',[0.25 0.4 0.65 0.25],...
        'background','w','fore','k',...
        'string',{'  '},'visible','off',...
        'fontsize',72);  
    
    % h(7)=uicontrol('units','normalized',...   %End program in middle of run if needed.
    %     'style','push','position',[0.37 0.22 0.25 0.08],...
    %     'background','w','fore',[1 0 0],...
    %     'string','Stop Program (if needed)','fontsize',16,...
    %     'callback','AAFdemo(''callend'')');     
    
    % h(8)=uicontrol('units','normalized',...      %Gender (needed for Audapter calibration)
    %     'style','check','position',[0.42 0.52 0.15 0.08],...
    %     'background',[1 1 1],'fore',[0 0 0],...
    %     'string','Plot results at the end','fontsize',14,'visible','off'); 

%############################### CALL START ###############################
elseif strcmpi(varargin,'callstart')==1   % if Start button is pushed
    
    set(h(1),'visible','off');
    set(h(3),'visible','off');
    
    countdown = 1; % Duration of countdown
    for nt = 1:countdown
        set(h(1), 'string', ...
                  ['Get ready: Experiment will start in ' ... 
                   num2str(countdown - nt + 1) ' seconds'], ...
                  'visible', 'on', 'position', [0.27 0.4 0.4 0.2], ...
                  'fontsize', 20);
        pause(1)
    end
    set(h(1),'visible','off');

    if photodiode==1
        h(9)=uicontrol('units','normalized',...   %photodiode box
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','k','fore','k');
        pause(1.0);
        h(9)=uicontrol('units','normalized',...   %text box for title
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','w','fore','w');        
    end

    h(7)=uicontrol('units','normalized',...   %End program in middle of run if needed.
                    'style','push','position',[0.37 0.22 0.25 0.08],...
                    'background','w','fore',[1 0 0],...
                    'string','Stop Program (if needed)','fontsize',16,...
                    'callback','AAFpilot(''callend'')'); 

    % Preparing Experiment
    [nTrials, seqWord, seqCond, seqF0shift, seqF1shift, seqF2angle] ...
        = generateParadigm();
    
    header = {'Subject ID', 'Gender', 'Trial #', 'Target Word', ...
              'Shift Type', '% F0 Shift', '% F1 Shift', 'F1-F2 angle', ...
              'Elapsed Time', 'Raw Data'};
    bigResults = cell(nTrials, size(header, 2));
    
    bigResults(:, 1) = {sinitials};
    bigResults(:, 2) = {gender};
    bigResults(:, 3) = num2cell(1:nTrials);
    bigResults(:, 4) = seqWord;
    bigResults(:, 5) = seqCond;
    bigResults(:, 6) = seqF0shift;
    bigResults(:, 7) = seqF1shift;
    bigResults(:, 8) = seqF2angle;

    % Record start time of the experiment
    experimentStart = tic;

    for thisTrial = 1:nTrials % Loop over each trial
        
        set(h(7), 'position',[0.46 0.1 0.08 0.08],...
            'background','w','fore',[1 0 0],...
            'string','Stop','fontsize',16,'visible','on');  

        thisWord = seqWord{thisTrial};
        thisCond = seqCond{thisTrial};

        thisF0shift = seqF0shift{thisTrial};
        thisF1shift = seqF1shift{thisTrial};
        thisF2angle = seqF2angle{thisTrial};

        if photodiode==1
            h(9)=uicontrol('units','normalized',...   %photodiode box
            'style','text','position',[0.01 0.01 0.1 0.1],...
            'background','k','fore','k');
            pause(0.01);
            h(9)=uicontrol('units','normalized',...   %text box for title
            'style','text','position',[0.01 0.01 0.1 0.1],...
            'background','w','fore','w');        
        end
        
        set(h(6),'string',thisWord,'visible','on','position',[0.4 0.4 0.2 0.2])  
       
        Audapter('reset');

        elapsedTime = toc(experimentStart);
        
        disp("Trial #" + num2str(thisTrial) + ": " + string(thisCond) ...
             + '(' + string(thisWord) + ')');

        % assuming there is no conditions shifting both F0 & F1
        if startsWith(thisCond, 'F0')
            AlteredAuditoryFeedback('F0', gender, AAFduration, ...
                                    1 + thisF0shift/100);
        elseif startsWith(thisCond, 'F1')
            AlteredAuditoryFeedback('F1', gender, AAFduration, ...
                                    thisF1shift/100, ...
                                    deg2rad(thisF2angle) );
        elseif startsWith(thisCond, 'control')
            AlteredAuditoryFeedback('none', gender, AAFduration);
        else % exception
            disp('Unknown experimental condition!');
            AAFpilot('endofrun');
        end

        rawData= AudapterIO('getData');

        bigResults{thisTrial, end - 1} = elapsedTime;
        bigResults{thisTrial, end} = rawData;

    end % End of trial loop (for thisTrial = 1:nTrials)
    
    AAFpilot('endofrun');

%################################ CALL END ################################
elseif strcmpi(varargin, 'callend') == 1  % if the STOP button is pushed

    close all;

    logsPath = fullfile(pwd, 'logs');
    if ~exist(logsPath, 'dir')
        mkdir(logsPath);
    end

    FinalData = [header; bigResults];

    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HHmmss');
    filename = 'AAFpilot(unexpected_end)_' + string(sinitials) + '_' + ...
                + string(timestamp);
    filepath = fullfile(pwd, 'logs', filename);
    save(filepath, 'FinalData');

    if photodiode==1
        h(9)=uicontrol('units','normalized',...   %photodiode box
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','k','fore','k');
        pause(1.5);
        h(9)=uicontrol('units','normalized',...   %text box for title
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','w','fore','w');        
    end

%############################### END OF RUN ###############################
elseif strcmpi(varargin,'endofrun') == 1  
    
    set(h(6), 'string', 'End of Run. Thank you!', 'fontsize', 32, ...
        'foreground', 'r');
    pause(2);
    
    clc; disp(' ');
    disp('Please wait: Saving data...');
    
    FinalData = [header; bigResults];

    logsDir = fullfile(pwd, 'logs');
    if ~exist(logsDir, 'dir')
        mkdir(logsDir);
    end

    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HHmmss');
    filename = "AAFpilot_" + string(sinitials) + '_' + string(timestamp);
    filepath = fullfile(pwd, 'logs', filename);
    save(filepath, 'FinalData');
    
    disp('Finished saving data in a .mat file named:');
    disp(filepath);
    
    if photodiode==1
        h(9)=uicontrol('units','normalized',...   %photodiode box
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','k','fore','k');
        pause(1.5);
        h(9)=uicontrol('units','normalized',...   %text box for title
        'style','text','position',[0.01 0.01 0.1 0.1],...
        'background','w','fore','w');        
    end

    close all;

end % if nargin == 0