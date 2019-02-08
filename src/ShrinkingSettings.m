classdef ShrinkingSettings
    properties
        mode;
        areaSize;
        numAzPos;
        sRange;
        sHeight;
        sDeltaRange;
        sWidth;
        sSectors;
        vShrinkingUp;
        thresholdUp;
        vShrinkingDown;
        thresholdDown;
    end
    methods
        function obj = ShrinkingSettings(areaSize_, numAzPos_, sRange_, ...
                sHeight_, sDeltaRange_, sWidth_, sSectorWeigth_, sSectorLims_,...
                vShrinkingUp_, thresholdUp_, vShrinkingDown_, thresholdDown_)
            if nargin == 12
                obj.mode = 'Shrinking'; % для использования в CloudGenerator
                obj.areaSize = areaSize_;
                obj.numAzPos = numAzPos_;
                obj.sRange = sRange_;
                obj.sHeight = sHeight_;
                obj.sDeltaRange = sDeltaRange_;
                obj.sWidth = sWidth_; 
                obj.sSectors = {sSectorLims_ ....
                    ShrinkingSettings.getWeight(sSectorWeigth_)};
                obj.vShrinkingUp = vShrinkingUp_;
                obj.thresholdUp = thresholdUp_;            
                obj.vShrinkingDown = vShrinkingDown_;
                obj.thresholdDown = thresholdDown_;
                return;
            end
        end
    end
    methods(Static, Access = private)
        function pdf = getWeight(weight)
            % Трансформирует вес попадания в каждый из секторов в
            % функцию вероятности для поиска случайного сектора при 
            % помощи rand() и find( > , 1, first')
            weight = weight ./sum(weight);
            pdf = zeros(size(weight));
            for i =1:length(weight)
                pdf(i) = sum(weight(1:i));
            end
        end
    end
end


%             obj.startingMinDeltaRange = 1;
%             obj.startingScopeDeltaRange = 3;
%             obj.startingNumIterations = 100;
%            obj.startingProbabilityForSectors = [3 12 3 1 41] / sum([3 12 3 1 41]);
%             obj.startingAnglesForSectors = [-180 -120 -60 0 60 120 180] * pi / 180;
%             obj.threshholdForFinish = 0.2;

%             obj.startingPersentShrinking = 0.02;
%             obj.startingScopeShrinking = 0.005;
%             obj.maxShrinkingAmplitude = 0.03;
%             obj.minShrinkingAmplitude = 0.03;
%             obj.deltaShrinking = 0.001;