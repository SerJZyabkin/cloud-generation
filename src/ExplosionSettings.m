classdef ExplosionSettings
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
    end
    methods
        function obj = ExplosionSettings()
            x = [3 30 15 30 3 3];
            s = [-180 -120 -60 0 60 120 180] * pi / 180;
            obj.mode = 'Shrinking';
            obj.areaSize = [400 701 701];
            obj.numAzPos = 314;
            obj.sRange = 40;
            obj.sHeight = 100;
            obj.sDeltaRange = [1 3 100]; % x1 + rand*x2, повторить x3 раз
            obj.sWidth = [2 15]; % x1 + rand*x2
            obj.sSectors = {s ExplosionSettings.getWeight(x)};
            obj.vShrinkingUp = {{0. 0.01 0.001 0.00 0.5 100 20} ...
                {0. 0.1 0.1 0.00 0.1 100 20}...
                {0. 0.3 0.3 0.00 0.3 20}};
            obj.thresholdUp = {{0.2 0.1} {0.1 0.1}};
        end
    end
    methods(Static, Access = private)
        function pdf = getWeight(weight)
            weight = weight ./sum(weight);
            pdf = zeros(size(weight));
            for i =1:length(weight)
                pdf(i) = sum(weight(1:i));
            end
        end
    end
end
% % %         function saveToFile(obj, path, name)
% % %             file = fopen([path name '.cgen'], 'wb', 'ieee-le');
% % %             fwrite(file,obj.startingRange,'double');
% % % %             fwrite(file,length(obj.vRangeChangeUp),'int');
% % % %             fwrite(file,obj.vRangeChangeUp,'double');
% % % %             fwrite(file,length(obj.vIterForChangeUp),'int');
% % % %             fwrite(file,obj.vIterForChangeUp,'double');
% % % %             fwrite(file,length(obj.vChangePosibilityUp),'int');
% % % %             fwrite(file,obj.vChangePosibilityUp,'double');
% % % %             fwrite(file,length(obj.vRangeChangeDown),'int');
% % % %             fwrite(file,obj.vRangeChangeDown,'double');
% % % %             fwrite(file,length(obj.vIterForChangeDown),'int');
% % % %             fwrite(file,obj.vIterForChangeDown,'double');
% % % %             fwrite(file,length(obj.vChangePosibilityDown),'int');
% % % %             fwrite(file,obj.vChangePosibilityDown,'double');
% % % %             fwrite(file,length(obj.vDirectionUp),'int');
% % % %             fwrite(file,obj.vDirectionUp,'double');
% % % %             fwrite(file,length(obj.vDirectionUpChange),'int');
% % % %             fwrite(file,obj.vDirectionUpChange,'double');           
% % % %             fwrite(file,length(obj.vIterForDirectionUp),'int');
% % % %             fwrite(file,obj.vIterForDirectionUp,'double');     
% % % %             fwrite(file,length(obj.vDirectionDown),'int');
% % % %             fwrite(file,obj.vDirectionDown,'double');   
% % % %             fwrite(file,length(obj.vDirectionDownChange),'int');
% % % %             fwrite(file,obj.vDirectionDownChange,'double');    
% % % %             fwrite(file,length(obj.vIterForDirectionDown),'int');
% % % %             fwrite(file,obj.vIterForDirectionDown,'double');          
% % % %             fwrite(file,length(obj.vWidthLayerChangeUp),'int');
% % % %             fwrite(file,obj.vWidthLayerChangeUp,'double'); 
% % % %             fwrite(file,length(obj.vProbabilityLayerChangeUp),'int');
% % % %             fwrite(file,obj.vProbabilityLayerChangeUp,'double');
% % % %             fwrite(file,length(obj.vIterForLayerChangeUp),'int');
% % % %             fwrite(file,obj.vIterForLayerChangeUp,'double');
% % %             fclose(file);
% % %         end
% % % 
% % %     end
% % % end