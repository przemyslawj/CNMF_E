function [signalPeaksArray] = getPeaks( F, stdThreshold )

    for i=1:size(F,1)
        inputSignal = F(i,:);
        inputSignalStd = std(inputSignal(:));
        [~,testpeaks] = findpeaks(inputSignal,...
            'minpeakheight',inputSignalStd * stdThreshold,...
            'minpeakdistance',10,...
            'minpeakprominence', 5,...
            'minpeakwidth', 2);

        signalPeaksArray{i} = testpeaks;
    end
end
