classdef LayerGenerator
    methods(Static)
        function vRange = makeRangeForShrinking(vAzimuth,settings)
            numElems = length(vAzimuth);
            vRange = zeros(numElems, 1);
            for iter = 1:settings.sDeltaRange(3)
                sectorID = find(cell2mat(...
                    settings.sSectors(2)) >= rand(),1,'first');

                hitAz = settings.sSectors{1}(sectorID) + ...
                    (settings.sSectors{1}(sectorID+1) - ...
                    settings.sSectors{1}(sectorID)) * rand();
                pos = find(hitAz <= vAzimuth,1,'first');
                deltaRange = settings.sDeltaRange(1) + ...
                    settings.sDeltaRange(2)* rand();
                deltaStep = round(settings.sWidth(1) * ...
                    (rand()*settings.sWidth(2)));
                if (deltaStep *2  >= numElems)
                    vRange = vRange + deltaRange;
                elseif (deltaStep >= pos)
                    vRange(1:pos+deltaStep) = vRange(1:pos+deltaStep) +...
                        deltaRange;
                    vRange(numElems + pos - deltaStep:numElems) = ...
                        vRange(numElems + pos - deltaStep:numElems) + ...
                        deltaRange;
                elseif (pos > numElems - deltaStep)
                    vRange(1:pos + deltaStep - numElems) = ...
                        vRange(1:pos + deltaStep - numElems) + ...
                        deltaRange;
                    vRange(pos - deltaStep:numElems) = vRange(pos - deltaStep:numElems) +...
                        deltaRange;
                else
                    vRange(pos-deltaStep:pos+deltaStep) =  ...
                        vRange(pos-deltaStep:pos+deltaStep) + ...
                        deltaRange;
                end
            end
            vRange(vRange < 0) = 0;
            vRange = vRange / max(vRange);
            vRange = vRange * settings.sRange;
        end
        
        function vRange = alterateShrinkingRange(vRange, settings)
            numElems = length(vRange);
            for iter = 1:settings(6)
                pos = ceil(numElems * rand());
                direction = sign(- settings(5) + rand());
                deltaWidth = ceil(settings(1) + settings(2) *rand());
                deltaRange = ceil(settings(3) + settings(4) *rand());
                if (deltaWidth *2  >= numElems)
                    vRange = vRange + deltaRange * direction;
                elseif (deltaWidth >= pos)
                    vRange(1:pos+deltaWidth) = vRange(1:pos+deltaWidth) +...
                        deltaRange * direction;
                    vRange(numElems + pos - deltaWidth:numElems) = ...
                        vRange(numElems + pos - deltaWidth:numElems) + ...
                        deltaRange * direction;
                elseif (pos > numElems - deltaWidth)
                    vRange(1:pos + deltaWidth - numElems) = ...
                        vRange(1:pos + deltaWidth - numElems) + ...
                        deltaRange * direction;
                    vRange(pos - deltaWidth:numElems) = vRange(pos - deltaWidth:numElems) +...
                        deltaRange * direction;
                else
                    vRange(pos-deltaWidth:pos+deltaWidth) =  ...
                        vRange(pos-deltaWidth:pos+deltaWidth) + ...
                        deltaRange * direction;
                end
                vRange(vRange < 0) = 0;
            end
        end
        
        function vRange = makeExplosionRange(startingRange, deltaRange , ...
                numElems, numIters, width, vProbability)
            vRange = zeros(numElems, 1) + startingRange;
            
            for iter = 1:numIters
                pos = ceil(numElems * rand())
                direction = - sign(rand() - vProbability);
                while 1
                    deltaStep = ceil(width * (rand()/2 + 0.5))
                    if (deltaStep *2  >= numElems)
                        vRange = vRange + deltaRange * direction;
                    elseif (deltaStep >= pos)
                        vRange(1:pos+deltaStep) = vRange(1:pos+deltaStep) +...
                            deltaRange * direction;
                        vRange(numElems + pos - deltaStep:numElems) = ...
                            vRange(numElems + pos - deltaStep:numElems) + ...
                            deltaRange * direction;
                    elseif (pos > numElems - deltaStep)
                        vRange(1:pos + deltaStep - numElems) = ...
                            vRange(1:pos + deltaStep - numElems) + ...
                            deltaRange * direction;
                        vRange(pos - deltaStep:numElems) = vRange(pos - deltaStep:numElems) +...
                            deltaRange * direction;
                    else
                        vRange(pos-deltaStep:pos+deltaStep) =  ...
                            vRange(pos-deltaStep:pos+deltaStep) + ...
                            deltaRange * direction;
                    end
                    break
                end
            end
            vRange(vRange < 0) = 0;
        end
        function displayLayer(az, range, xAxes, yAxes, array)
            figure('units','normalized','outerposition',[0.18 0.05 0.64 0.9])
            subplot(2,2,3); polarplot(az, range,'k', 'LineWidth', 2);%, ThetaZeroLocation, 'top');
            set(gca, 'ThetaZeroLocation', 'top');
            set(gca, 'ThetaDir', 'clockwise');

            az = az * 180 / pi;
            subplot(2,2,[1 2]); plot(az, range,'k', 'LineWidth', 2); xlim([min(az) max(az)]);
            subplot(2,2,4); imagesc(xAxes, yAxes,array');
            set(gca,'YDir','normal')
        end
        
        function [xAxes, yAxes] = shiftLayer(xAxes, yAxes, centerShift)
            if (length(centerShift) == 2)
                xAxes = xAxes - centerShift(1);
                yAxes = yAxes - centerShift(2);
                return
            end
            disp(['LayerGenerator: Failed to shift layer! Vectors remain unchanged.']);
        end
        
        function [xAxes, yAxes, layer] = fillExplosionArea(vAzimuth, vRange)
            maxRange = ceil(max(vRange));
            xAxes = (-maxRange) : maxRange;
            yAxes = (-maxRange) : maxRange;
            layer = zeros(length(xAxes), length(yAxes));
            for xStep = 1:length(layer(:,1)) % —канирование массива слева направо
                for yStep = 1:length(layer(1,:))  % —канирование массива снизу вверх
                    
                    % –ассто€ние до искомой области пространства
                    rangeValue = sqrt(xAxes(xStep).^2+ yAxes(yStep).^2);
                    if rangeValue < maxRange  % ƒл€ уменьшени€ расчета
                        
                        % јзимутальное направление на область пространства
                        azimuth = atan2(xAxes(xStep), yAxes(yStep));
                        
                        % »ндекс этого направлени€ в массиве возможных азимутов
                        indexAzimuth = find(vAzimuth < azimuth,1, 'last');
                        
                        % ≈сли индекс не найден (больше, чем max)
                        if isempty(indexAzimuth) == true
                            indexAzimuth = 1; % ... приравниваем первому
                        end
                        
                        % ѕроверка попадани€ в требуемый контур
                        if (rangeValue < vRange(indexAzimuth))
                            layer(xStep,yStep) = 1;
                        end
                    end
                end
            end         
        end
    end
end