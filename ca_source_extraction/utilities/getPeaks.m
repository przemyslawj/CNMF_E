function [signalPeaksArray] = getPeaks( F, stdThreshold )

    for i=1:size(F,1)
        inputSignal = F(i,:);
        inputSignalStd = std(inputSignal(:));
        [~,testpeaks] = findpeaks(inputSignal,...
            'minpeakheight',inputSignalStd * stdThreshold,...
            'minpeakdistance',10);

        signalPeaksArray{i} = testpeaks;
    end
end
