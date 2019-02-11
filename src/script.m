% ����� ShrinkingSettings �������� ��������� ��� �������� ������
% ������ ������ ���������:  settings = ShrinkingSettings(areaSize_, ...
% numAzPos_, sRange_, sHeight_, sDeltaRange_, sWidth_, sSectorWeigth_,...
% sSectorLims_,  vShrinkingUp_, thresholdUp_, vShrinkingDown_, thresholdDown_);

%��������:
% 1 ��������� �������:
areaSize = [200 301 301]; % ��������� ������� ������� ������������� ������
% � ������� ������/��������/��������. ������ ����������� �����. ������ 
% ��� ��������� ���������� ��������������, ��� areaSize(2:3)mod2 = 1 

% 1.1 ��������� ��������� �������. 's' for starting:
numAzPos = 315; % ����� ������������ ������� �������� ��..2pi / numAzPos ~ 1 
                % ������ ����� ��������� �������� ������ 
sRange = 100; % ������������ ������ ��������� �������, ����������� � ��������
sHeight = 150; % ������ ������ ������� ���������� �������
% ������� ������������ ���������� �������:
sDeltaRange = [1 3 100]; % ��������� ��� �3 ���. �������� � ��������� x1 + rand*x2
    % ����������� � %. ������ �� 100 �������� ����� �������� ������ �� ����. 
    % � ����� ��� ����������� �� ������������� ��������, ������� ����� ���������� 
    % ����� sRange ��������
sWidth = [2 15]; % ��������� �� x1 + rand*x2 ������������ �������
    % ����������� � ������������ ��������, ������������ numAzPos
sSectorWeigth= [10 30 10 3 3 3]; % ������, ����� ������� �������� ������� � ������ 
sSectorLims = [-180 -120 -60 0 60 120 180] * pi / 180; % ������� ������������� 
% ��������� ��� ��������� �������� � ��������, ������ length(sSectorWeigth_) == 
% length(sSectorLims_), � sSectorLims_ = [-pi:pi] 

% 1.2 ������������ ������ ����� ����� ��������� ������� ���������� �������
vShrinkingUp = {{20 10 0 0.1 0.5 50 5} ... % ����� ������ ����� ����� ������
    {20 10 0 0.2 0.4 50 5}... % � ���� ����� �� 7 �������. � ������ ������ 3 ������.
    {30 10 0 0.5 0.8 100}}; % ������ ������ ����������� ������ ������ ������� �� 1 
% � ������������ ������ ����. ������ ���� ������������ ����������. �6
% �������� �� ����� ��������. �5 ���������� ����������� ����, ��� ��������
% �������� ������, � �� ��������. �� ����� ������ �������� ����������
% ��������� ������������ �������, ������ ������� � �������� �1 + x2 *
% rand(1) ���������� ��������� ������� �� �������� x3 + �4 * rand().
% ��������� ������ ����������� ����������.
thresholdUp = {[0.5 1] [0.5 1] [0.5 1]}; % ������ ������������ �������
% ���������� ����� ���� �1 �������� ������ ������ �2. �������� ������� 
% �������� ��� ������ ������ �� vShrinkingUp, �.�. ������� ���� cell'��
% ������ ���� �����. ����� ������������ ����������� � ������, ���� ������
% �������� ������������ ������ �������

% 1.3 ����������� ������������ ������ ���� ���������� ������� ���������� �������
vShrinkingDown = {{20 10 0 0.1 0.5 50 5} ... 
    {30 10 0 0.5 0.8 100}};
thresholdDown = {[0.2 1] [0.6 1]};

% 1.4 ��������� ��������� ��������
settings = ShrinkingSettings(areaSize, numAzPos, sRange, ...
    sHeight, sDeltaRange, sWidth, sSectorWeigth, sSectorLims,...
    vShrinkingUp, thresholdUp, vShrinkingDown, thresholdDown);

% 2 ����� �� ��������� ����� �������� ����������� ������ ��������� ���������:
obj_1 = CloudGenerator.generateCloud(settings,1);
obj_1.displayCloudWithMarkers(1,'r',10); % x1 - ����������� ������ ���������,
% x2 - ���� �������, �3 - ������ �������, ��� ������������� ����� ������
% ���, �� ������� ���������� �����������, ����� ���������� 4 ���������,
% �������� ax = gca; obj_1.displayCloudWithMarkers(1,'r',10,ax);

% 3 ��� ������������ ������ ������ ���������� �������� ���������, ����
% ������������ �����
settings.sRange = 50;
obj_2 = CloudGenerator.generateCloud(settings,5);

% 4 ����� ������� ������ ���������� ����� ���������� ��� ������������
    % ���������� �������� �������� 
obj_s = obj_1.mergeClouds(obj_2, [0 10 10]); %��� �2 - ����� ���������������
    % ������� ������������ ��������

% 5 ����� �������� ������� ��� ���������� ��������, ������������
% ����������� ��������������� ������ ��������:
obj_sf = obj_s.filtrateCubic([3 3 3], 0.4); % [3 3 3] ������� ���� � �������
    % 0.4 - ����������� ����� ����������� �������� ��������� � ������ ����

% ��� ����� ����������� ������ ���������� ������� ����������� �������
% ������� � ��������� ���������.
figure('units','normalized','outerposition',[0.10 0.05 0.8 0.9])
subplot(2,1,1);
obj_s.displayContour(150,1,[],[],gca); % �1 - ������, �� �������� ������������
    % �������, �2 - ���(1 - �������������� ������� ���, 2 - ������������
    % ������� �HY, 3 - ������������ ������� �HX. �3 � �4 - ������� �� ����,
    % �5 - ��� ����������� �������. 

subplot(2,1,2);
obj_sf.displayContour(150,1,'x_index','y_index',gca); 


% 6 ����� ������� ������ ����� �������������� � ���� ��� �����������
obj_sf.convertForVisual('E:\','testCloud_Shifted',100,1,[0 1000 1000], [100 200 200]);
obj_sf.convertForVisual('E:\','testCloud',500,1,[0 0 0], [100 200 200]);