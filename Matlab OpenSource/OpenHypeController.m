close all
load("Settings.mat"); % Load Paramters
Test=0;       % Set test to 1 for continuous capturing
OnlinePlot=0; % Set onlineplot to 1 to visualize the scene while capturing (this will make scanning a bit slow)
NLines = 400; % Number of lines (resolution in the y-direction)
ScanLimit=0.7;% This specifies ow much to scan from the sceen (use 1 for full y-direction scan)
light = 0.9;  % 0-1, use lower value for low light conditions
COMPort = 6;  % serial port of the arduino
Exposure = -4;
%% Creat Arduino and DAC
clear arduinoObj i2cdac 
arduinoObj = arduino(['COM',num2str(COMPort)],"Uno","Libraries","I2C");
i2cdac = device(arduinoObj,'I2CAddress','0x62','bitrate',400000);
disp(arduinoObj)
disp(i2cdac)
%% This will sned send 10 pulses to the mirror and will cuase the device to produce a slight "buzz" sound
disp("Sending test signal")
writeDigitalPin(arduinoObj,"D13",1); % enable the mirror controller
pause(1)
for i=1:10
    write(i2cdac,ConverDAC(0))
    write(i2cdac,ConverDAC(4095))
end
writeDigitalPin(arduinoObj,"D13",0); % disable the mirror controller

%% Open USB Camera
% Some cameras have different settings, you can list camera settings using
% "cam" command
clear cam
cam = webcam(WebCamName);
cam.Brightness=Brightness;
cam.Contrast=Contrast;
cam.Exposure=Exposure;
cam.Sharpness=Sharpness;
cam.Gamma=Gamma;
cam.ExposureMode='manual';
disp(cam)
%% Capturing loop
clear img
writeDigitalPin(arduinoObj,"D13",1); % enable the mirror controller (CMOS switch)
pause(1)
WLines = min(round(ROI(4)),720-ROI(2)+1); % calcualte number of pixels in the x-direction
NColors = round(ROI(3)); % claculate number of pixels in the z-direction (lambda)

AspectR =500*ScanLimit; % you can adjust this value according to your camera

tic
while(1)
    img=uint8(zeros(NLines,WLines,NColors));
    write(i2cdac,ConverDAC(0)); % Send DAC value
    for ctr=1:3 % Clear the camera buffer
        sp = snapshot(cam);
    end
    for ctr=1:NLines
        ADCValue = 4096-((4096*ScanLimit-1)/(NLines)*(ctr-1));
        write(i2cdac,ConverDAC(ADCValue))
        pause(0.05)
        sp = rgb2gray(snapshot(cam));
        sp=imcrop(sp,ROI);
        sp(size(img,2)+1:end,:)=[];
        sp(:,size(img,3)+1:end)=[];
                    
        img(ctr,:,:) = sp;
        disp(ctr)

        if OnlinePlot==1
            figure(2)
            AA=mat2gray(squeeze(sum(img(:,:,:),3)));
            if NLines<=WLines
                AA=mat2gray(imresize(AA,size(AA).*[AspectR/NLines 1]));
            else
                AA=mat2gray(imresize(AA,size(AA).*[1 NLines/AspectR]));
            end
            AA = imadjust(AA);
            imshow(AA)
            drawnow;

        end

    end

    write(i2cdac,ConverDAC(2048))

    % Test reconstracting RGB
    % this uses a very simple RGB reconstruction by deviding the spectrum
    % into three poritions for R, G, and B
    figure(3)
    clear Stacked
    Red=img(:,:,round(2/3*NColors):end);
    Stacked(:,:,1)=mat2gray(squeeze(sum(Red,3)));
    Grn=img(:,:,round(1/3*NColors):round(2/3*NColors));
    Stacked(:,:,2)=mat2gray(squeeze(sum(Grn,3)));

    Blu=img(:,:,1:round(1/3*NColors));
    Stacked(:,:,3)=mat2gray(squeeze(sum(Blu,3)));

    Stacked = imresize(Stacked,[800*ScanLimit 600],"bilinear");

    Stacked2 = imadjust(Stacked,[0 0 0; light light light],[]);
    imshow(Stacked2)
    drawnow


    if Test~=1
        break;
    end

end
toc
writeDigitalPin(arduinoObj,"D13",0); % disable the mirror controller (CMOS switch off)
%% Save the datacube (optional)
save('HyperSpectralDataCube.mat',"NLines","NColors","WLines","img","AspectR","ScanLimit")

