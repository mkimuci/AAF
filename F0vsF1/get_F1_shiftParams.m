function [shiftRate, shiftAngle] = get_F1_shiftParams(expt, itrial)
    shiftMag = expt.shiftMag;
    condition = expt.trials{itrial}.cond;
    
    % Determine F1 shift parameters based on condition
    switch condition
        case 'shiftUp'
            shiftRate = shiftMag;
            shiftAngle = 0; % Use default angle
        case 'shiftDown'
            shiftRate = -shiftMag;
            shiftAngle = 0; % Use default angle
        otherwise
            shiftRate = 0;
            shiftAngle = 0;
    end
end
