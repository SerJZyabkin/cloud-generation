classdef CloudGenerator
    methods(Static)
        function cloudObj = generateCloud(settings, dangerID)
            switch settings.mode
                case 'Explosion'
                    disp('CloudGenerator: Creating cloud by explosion.');
                    %cloudObj = CloudGenerator.explode(settings);
                    return;
                case 'Shrinking'
                    disp('CloudGenerator: Creating cloud by shrinking.');
                    cloudObj = CloudGenerator.shrink(settings);
                otherwise
                    disp(['CloudGenerator: Unused settings received.'...
                        'Returning 0.']);
                    cloudObj = 0;
                    return;
            end
            cloudObj.phenomenaMatrix = ...
                cloudObj.phenomenaMatrix * dangerID;
        end
    end
    methods(Access = private)
    end
    methods(Access = private, Static)
        function cloudObj = shrink(settings)
            cloudObj = CloudObject(settings.areaSize);
            az = -pi:2*pi/settings.numAzPos:pi;
            center = [settings.sHeight ceil(settings.areaSize(2:3)/2)];
            curCenter = center;
            vInitialRange = LayerGenerator.makeRangeForShrinking(az, settings);
            [xAxes, yAxes, layerArray] = ...
                 LayerGenerator.fillExplosionArea(az,vInitialRange);
            cloudObj = CloudGenerator.setCloudLayer(cloudObj, center(1), ...
                    center(2) + min(xAxes), center(3) + min(yAxes), layerArray);
            curCenter(1) = curCenter(1) + 1;
            counter = 0;
            curIterIndex = 1;
            vRange = vInitialRange;
            while curCenter(1) <= settings.areaSize(1)
                if curIterIndex < length(settings.thresholdUp)
                    if counter > cell2mat(settings.vShrinkingUp{curIterIndex}(7))
                        counter = 0;
                        curIterIndex = curIterIndex + 1;
                    else
                        counter = counter + 1;
                    end
                end

                vRange = LayerGenerator.alterateShrinkingRange(vRange,...
                    cell2mat(settings.vShrinkingUp{curIterIndex}(1:6)));
                disp(['Height = ' num2str(curCenter(1))]);
                [xAxes, yAxes, layerArray] = ...
                    LayerGenerator.fillExplosionArea(az,vRange);
                cloudObj = CloudGenerator.setCloudLayer(cloudObj, curCenter(1), ...
                    curCenter(2) + min(xAxes), curCenter(3) + min(yAxes), layerArray);
                curCenter(1) = curCenter(1) + 1;
                numLowVals = length(find(vRange <...
                    settings.thresholdUp{curIterIndex}(2)));
                if (settings.thresholdUp{curIterIndex}(1) < ...
                        numLowVals/settings.numAzPos)
                    break;
                end
            end 

            vRange = vInitialRange;
            curCenter = center;
            curCenter(1) = curCenter(1) - 1;
            curIterIndex = 1;
            counter = 0;
            while curCenter(1) > 0
                if curIterIndex < length(settings.thresholdDown)
                    if counter > cell2mat(settings.vShrinkingDown{curIterIndex}(7))
                        counter = 0;
                        curIterIndex = curIterIndex + 1;
                    else
                        counter = counter + 1;
                    end
                end
                vRange = LayerGenerator.alterateShrinkingRange(vRange,...
                    cell2mat(settings.vShrinkingDown{curIterIndex}(1:6)));
                disp(['Height = ' num2str(curCenter(1))]);
                [xAxes, yAxes, layerArray] = ...
                    LayerGenerator.fillExplosionArea(az,vRange);
                cloudObj = CloudGenerator.setCloudLayer(cloudObj, curCenter(1), ...
                    curCenter(2) + min(xAxes), curCenter(3) + min(yAxes), layerArray);
                curCenter(1) = curCenter(1) - 1;
                numLowVals = length(find(vRange <...
                    settings.thresholdDown{curIterIndex}(2)));
                if (settings.thresholdDown{curIterIndex}(1) < ...
                        numLowVals/settings.numAzPos)
                    break;
                end
            end 
        end

        function cloudObj = setCloudLayer(cloudObj, h0Index, x0Index, ...
                  y0Index, layerArray)
            sizes = size(cloudObj.phenomenaMatrix);
            % ¬ыбор номера сло€(контура) по высоте
            if (h0Index >  sizes(1))
                disp(['CloudGenerator: Failed to add layer to cloud ' ...
                    'at height with index = ' num2str(h0Index)]);
                return;
            end
            % ѕроверка попадани€ контура в рабочую плоскость на высоте h0
            if ((x0Index + length(layerArray(:,1)) < 1) || ...
                   (x0Index > sizes(2)))
                disp(['CloudGenerator: Failed to add layer on height '... 
                    'ID = ' num2str(h0Index) ' to cloud. xAxis is out '...
                    'of boundaries']);
                return;
            elseif ((y0Index + length(layerArray(1,:)) < 1) || ...
                   (y0Index  > sizes(3)))
                disp(['CloudGenerator: Failed to add layer on height '... 
                    'ID = ' num2str(h0Index) ' to cloud. yAxis is out '...
                    'of boundaries']);
                return;
            end

            % ѕоиск начала области вставки по оси ’
            % ќтработка случаев, когда не весь слой влезает в облако
            if (x0Index < 1)
                firstX_ID = 1;
                layerArray(1:abs(x0Index)+ 1,:) = [];
                disp(['CloudGenerator: Layer is partly belong to working '... 
                    'area. Removing ' num2str(abs(x0Index) + 1) ' first '...
                    'rows of xAxis data to fit inside boundaries']);
                x0Index = firstX_ID;
            else
                firstX_ID = x0Index;
            end  
            if ((x0Index + length(layerArray(:,1) + 1) > sizes(2)))
                lastX_ID = sizes(2);             
                disp(['CloudGenerator: Layer is partly belong to working '... 
                    'area. Removing ' num2str(length(layerArray(:,1)) - ...
                    sizes(2) + x0Index - 1) ' last '...
                    'rows of yAxis data to fit inside boundaries']);
                layerArray(sizes(2) - x0Index + 2:...
                    length(layerArray(:,1)),:) = [];           
            else
                lastX_ID = x0Index + length(layerArray(:,1)) - 1;
            end
            
            % ѕоиск начала области вставки по оси Y
            % ќтработка случаев, когда не весь слой влезает в облако
            if (y0Index < 1)
                firstY_ID = 1;
                layerArray(:, 1:abs(y0Index)+ 1) = [];
                disp(['CloudGenerator: Layer is partly belong to working '... 
                    'area. Removing ' num2str(abs(y0Index) + 1) ' first '...
                    'rows of yAxis data to fit inside boundaries']);
                y0Index = firstY_ID;
            else
                firstY_ID = y0Index;
            end   
            
            if ((y0Index + length(layerArray(1,:) + 1) > sizes(3)))
                lastY_ID = sizes(3);             
                disp(['CloudGenerator: Layer is partly belong to working '... 
                    'area. Removing ' num2str(length(layerArray(1,:)) - ...
                    sizes(3) + y0Index - 1) ' last '...
                    'rows of yAxis data to fit inside boundaries']);
                layerArray(:,sizes(3) - y0Index + 2:...
                    length(layerArray(1,:))) = [];           
            else
                lastY_ID = y0Index + length(layerArray(1,:)) - 1;
            end
            
            % ‘инальное присвоение области к рабочему массиву
            cloudObj.phenomenaMatrix(h0Index, firstX_ID:lastX_ID,...
                firstY_ID:lastY_ID) = layerArray;
            return;
        end
    end
end

%         function vRangeReduction = decimateRangeVector(lengthR, vShrinking)
%             prevR = vShrinking(1) + rand() * vShrinking(2); 
%             vRangeReduction = zeros(1,lengthR);
%             for i = 1:lengthR
%                 vRangeReduction(i) = prevR + sign(rand() - 0.5) * ...
%                     vShrinking(3) * rand();
%                 if (vRangeReduction(i) >= vShrinking(4) && ...
%                         vRangeReduction(i) <= vShrinking(5))
%                     prevR = vRangeReduction(i);
%                 end 
%             end
%         end

% function cloudObj = explode(settings)
%             cloudObj = CloudObject(settings.areaSize);
%             curRange = settings.startingRange;
%             curCenter = [settings.startingHeight ...
%                 ceil(settings.areaSize(2:3) / 2)];
%             az = -pi:0.1:pi;
%             iterNum = 0;
%             stageNum = 1;
%             
%             initialRangeVector = LayerGenerator.makeExplosionRange(curRange,...
%                 settings.vRangeGenerationChange(1), ...
%                     length(az), settings.vNumChangesPerRangeCalc(1), ...
%                     settings.vRangeWidthUp(1), settings.vRangeIncreaseProb(1));
%             [xAxes, yAxes, layerArray] = ...
%                 LayerGenerator.fillExplosionArea(az,initialRangeVector);
%             imagesc(layerArray);
% %             while (curRange > 1 && curCenter(3) < settings.areaSize(1))
% %                 range = LayerGenerator.makeExplosionRange(curRange, 3, ...
% %                     length(az), 25, [6 4 2 1], [1 0.9 0.8 0.2]);
% %                 [xAxes, yAxes, layerArray] = ...
% %                     LayerGenerator.fillExplosionArea(az,range);
% %                 cloudObj = CloudGenerator.setCloudLayer(cloudObj, curCenter(3), ...
% %                     curCenter(1) + min(xAxes), curCenter(2) +...
% %                     min(yAxes), layerArray * dangerID);
% %                 curCenter(3) = curCenter(3) + 1;
% %                 curRange = curRange - obj.vRangeChangeUp(1) * rand();
% %             end
%             return;
%         end



%         function cloudObj = setCloudLayer(cloudObj, h0Index, x0Index, ...
%                   y0Index, layerArray)
%             % ¬ыбор номера сло€(контура) по высоте
%             if (h0Index > cloudObj.sizeH)
%                 disp(['CloudGenerator: Failed to add layer to cloud ' ...
%                     'at height with index = ' num2str(h0Index)]);
%                 return;
%             end
%             % ѕроверка попадани€ контура в рабочую плоскость на высоте h0
%             if ((x0Index + length(layerArray(:,1)) < 1) || ...
%                    (x0Index > cloudObj.sizeX))
%                 disp(['CloudGenerator: Failed to add layer on height '... 
%                     'ID = ' num2str(h0Index) ' to cloud. xAxis is out '...
%                     'of boundaries']);
%                 return;
%             elseif ((y0Index + length(layerArray(1,:)) < 1) || ...
%                    (y0Index  > cloudObj.sizeY))
%                 disp(['CloudGenerator: Failed to add layer on height '... 
%                     'ID = ' num2str(h0Index) ' to cloud. yAxis is out '...
%                     'of boundaries']);
%                 return;
%             end
% 
%             % ѕоиск начала области вставки по оси ’
%             % ќтработка случаев, когда не весь слой влезает в облако
%             if (x0Index < 1)
%                 firstX_ID = 1;
%                 layerArray(1:abs(x0Index)+ 1,:) = [];
%                 disp(['CloudGenerator: Layer is partly belong to working '... 
%                     'area. Removing ' num2str(abs(x0Index) + 1) ' first '...
%                     'rows of xAxis data to fit inside boundaries']);
%                 x0Index = firstX_ID;
%             else
%                 firstX_ID = x0Index;
%             end  
%             if ((x0Index + length(layerArray(:,1) + 1) > cloudObj.sizeX))
%                 lastX_ID = cloudObj.sizeX;             
%                 disp(['CloudGenerator: Layer is partly belong to working '... 
%                     'area. Removing ' num2str(length(layerArray(:,1)) - ...
%                     cloudObj.sizeX + x0Index - 1) ' last '...
%                     'rows of yAxis data to fit inside boundaries']);
%                 layerArray(cloudObj.sizeX - x0Index + 2:...
%                     length(layerArray(:,1)),:) = [];           
%             else
%                 lastX_ID = x0Index + length(layerArray(:,1)) - 1;
%             end
%             
%             % ѕоиск начала области вставки по оси Y
%             % ќтработка случаев, когда не весь слой влезает в облако
%             if (y0Index < 1)
%                 firstY_ID = 1;
%                 layerArray(:, 1:abs(y0Index)+ 1) = [];
%                 disp(['CloudGenerator: Layer is partly belong to working '... 
%                     'area. Removing ' num2str(abs(y0Index) + 1) ' first '...
%                     'rows of yAxis data to fit inside boundaries']);
%                 y0Index = firstY_ID;
%             else
%                 firstY_ID = y0Index;
%             end   
%             
%             if ((y0Index + length(layerArray(1,:) + 1) > cloudObj.sizeY))
%                 lastY_ID = cloudObj.sizeY;             
%                 disp(['CloudGenerator: Layer is partly belong to working '... 
%                     'area. Removing ' num2str(length(layerArray(1,:)) - ...
%                     cloudObj.sizeY + y0Index - 1) ' last '...
%                     'rows of yAxis data to fit inside boundaries']);
%                 layerArray(:,cloudObj.sizeY - y0Index + 2:...
%                     length(layerArray(1,:))) = [];           
%             else
%                 lastY_ID = y0Index + length(layerArray(1,:)) - 1;
%             end
%             
%             % ‘инальное присвоение области к рабочему массиву
%             cloudObj.phenomenaMatrix(h0Index, firstX_ID:lastX_ID,...
%                 firstY_ID:lastY_ID) = layerArray;
%             return;
%         end



%         function cloudObj = explodeArea(obj, areaSize, ...
%                 explosionCenter, dangerID)
%                 cloudObj = CloudObject(areaSize(1), areaSize(2), areaSize(3));
%                 curRange = obj.startingRange;
%                 curCenter = explosionCenter;
%                 az = -pi:0.1:pi;
%                 
%                 while (curRange > 1 && curCenter(3) < cloudObj.sizeH)
%                     range = LayerGenerator.makeExplosionRange(curRange, 3, ...
%                         length(az), 25, [6 4 2 1], [1 0.9 0.8 0.2]);
%                     [xAxes, yAxes, layerArray] = ...
%                         LayerGenerator.fillExplosionArea(az,range);
%                     cloudObj = CloudGenerator.setCloudLayer(cloudObj, curCenter(3), ...
%                         curCenter(1) + min(xAxes), curCenter(2) +...
%                         min(yAxes), layerArray * dangerID);
%                     curCenter(3) = curCenter(3) + 1;
%                     curRange = curRange - obj.vRangeChangeUp(1) * rand();
%                 end
%             return;
%         end
%         function obj = extractFromFile(path, name)
%             file = fopen([path name '.cgen'], 'rb');
%             obj = CloudGenerator(...
%                 fread(file,1,'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'),...
%                 fread(file,fread(file,1,'int'),'double'));
%             fclose(file);
%         end