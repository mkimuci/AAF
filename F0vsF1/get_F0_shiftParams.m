function shiftRate = get_F0_shiftParams(expt, itrial)
    condition = expt.trials{itrial}.cond;
    
    % Determine F0 shift parameters based on condition
    switch condition
        case 'shiftUp'
            shiftRate = 50;  % Example shift value for F0 up
        case 'shiftDown'
            shiftRate = -50; % Example shift value for F0 down
        otherwise
            shiftRate = 0;   % No shift
    end
end
