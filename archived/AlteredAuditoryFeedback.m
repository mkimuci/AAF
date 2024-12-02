% function AlteredAuditoryFeedback for AAF Experiments
% Written by Minkyu Kim, Kourosh Saberi, Oren Poliva
% 1st draft 03-02-2024

function AlteredAuditoryFeedback(mode, pitchGender, duration, varargin)

    % Configurations (for UC Irvine ALNS)
    audioInterfaceName = 'Focusrite USB';
    Audapter('deviceName', audioInterfaceName);
    
    % not sure what this does - MK
    Audapter('ost', '', 0);
    Audapter('pcf', '', 0);
    
    % Generate Audapter's default parameters
    params = getAudapterDefaultParams(pitchGender);
    
    switch mode
        case "F0"
            F0shiftRate = varargin{1};
                
            if isequal(lower(pitchGender), 'female')
                params.pitchLowerBoundHz = 150;
                params.pitchUpperBoundHz = 300;
            elseif isequal(lower(pitchGender), 'male')
                params.pitchLowerBoundHz = 80;
                params.pitchUpperBoundHz = 160;
            end
            
            params.bTimeDomainShift = 1;

            % not sure what this does at the moment - MK
            params.nDelay = 7;
            params.bCepsLift = 1;
            params.timeDomainPitchShiftAlgorithm = 'pp_none';
        
            params.rmsThresh = 0.011;
            
            % no delay, shift immediately
            params.timeDomainPitchShiftSchedule = [0, F0shiftRate];  
        
        case "F1"
        
            F1shiftRate = varargin{1};
            F1F2angleRad = varargin{2};
            
            % This is actually the default settings
            % We can change if we want
            params.f1Min = 0;
            params.f1Max = 5000;  
            params.f2Min = 0;
            params.f2Max = 5000;  
    
            % INDEPENDENT VARIABLE OF THE PERTURBATION FIELD (0 to 5000 HZ)
            params.pertF2 = linspace(0, 5000, 257);   
            params.pertAmp = F1shiftRate * ones(1, 257);
            params.pertPhi = F1F2angleRad * ones(1, 257);
            params.bTrack = 1;
            params.bShift = 1;
            params.bRatioShift = 1;
            params.bMelShift = 0;
    
        otherwise
            % do nothing
    end
    
    AudapterIO('init', params);
    AudapterIO('reset');
    
    Audapter('start');
    pause(duration);
    Audapter('stop');

return