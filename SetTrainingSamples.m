function SetTrainingSamples(Xinitial,Xinterval,Yinitial,Yinterval)

TrainingFilePath = uigetdir( 'selet the path of training files'); %select folder where training video and label files are

VideoFile=[TrainingFilePath,'\TrainingVideo.avi']; 
GroomingFile=[TrainingFilePath,'\LabeledGrooming.txt'];
LocomotionFile=[TrainingFilePath,'\LabeledLocomotion.txt'];
RestingFile=[TrainingFilePath,'\LabeledResting.txt'];
SavePath=[TrainingFilePath '\Features'];
mkdir(SavePath);

load('Parameters')

BackgroundUpdate = BackgroundRate*60*FrameRate; %Update background every 'BackgroundUpadate' frames. Set in 'Setting Parameters > Advanced Setting'
AnalyzingStep = FrameRate/AnalyzingRate; % Step size to analyze the video. To analyze all frames, FrameRate = AnalyzingRate. Set in 'Setting Parameters'
TubeEdgeX = [Xinitial:Xinterval:Xinitial+Ncolumn*Xinterval]; %Boundaries of each tube, set by sliders in 'GroomingDetector' panel
TubeEdgeY = [Yinitial:Yinterval:Yinitial+Nrow*Yinterval];
TubeArea = int16([Yinterval,Xinterval]); % Dimension of area for each tube

['Initializing......']

    mov=VideoReader(char(VideoFile)); % Creat movie object
    Nframe=get(mov,'NumberOfFrames'); % # of frames in raw video
    OutputNframe=ceil(Nframe/AnalyzingStep); % # of frames to analyze
    Xposition=zeros(Nrow,Ncolumn,OutputNframe); % Output horizontal positions of all flies through a video
    Yposition=zeros(Nrow,Ncolumn,OutputNframe); % Vertical positions
    SizeofFly=zeros(Nrow,Ncolumn,OutputNframe); % Size of flies in units of pixels, used for feature normalization
    PeripheryMovement=zeros(Nrow,Ncolumn,OutputNframe); % Feature PM
    CoreMovement=zeros(Nrow,Ncolumn,OutputNframe); % Feature CM
    CurrentPeriphery=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % PM in current frame
    CurrentCore=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % CM in current frame
    index1=0;
    
    timenow=datestr(now,0);
    disp([timenow ' Processing video'])
    processingstage=0;
    for i=1:VideoBatchSize:Nframe
%         i
    %-------------------- setting background --------------------------
        if mod(i,BackgroundUpdate)==1 & (Nframe-i > BackgroundUpdate | Nframe < BackgroundUpdate)
            TemplateFrame=read(mov,i);
            TemplateFrame=rgb2gray(TemplateFrame);
            if TransVideo==1
                TemplateFrame=TemplateFrame';
            end
            Ncontrast=floor(linspace(i+1,i+min(BackgroundUpdate,Nframe)-1,NumberofContrast));
            for j=1:NumberofContrast
                ContrastFrame=read(mov,Ncontrast(j));
                ContrastFrame=rgb2gray(ContrastFrame);
                if TransVideo==1
                    ContrastFrame=ContrastFrame';
                end
                TemplateFrame(TemplateFrame<=ContrastFrame-C0)=ContrastFrame(TemplateFrame<=ContrastFrame-C0); 
                % Compare TemplateFrame with each ContrastFrame to create a background
            end
        end
     %------ Read video to memory every VideoBatchSize frames -----------    
        if Nframe-i > VideoBatchSize-2
            CurrentClip=read(mov,[i,i+VideoBatchSize-1]);
        else
            CurrentClip=read(mov,[i,Nframe]);
        end       
    %------- Extract fly positions, sizes and features every AnalyzingStep frames------------
        for k=1:AnalyzingStep:size(CurrentClip,4)
            index1=index1+1;
            if index1>OutputNframe/100*processingstage
                disp(['Extracting features. Progress : ' num2str(processingstage) '%' ])
                processingstage=processingstage+10;    
            end
            CurrentFrame=CurrentClip(:,:,:,k); % A CurrentFrame for analyzing
            CurrentFrame=rgb2gray(CurrentFrame);
            if TransVideo==1
                CurrentFrame=CurrentFrame';
            end
            Diff=zeros(size(CurrentFrame));
            Diff(CurrentFrame<=TemplateFrame-C0)=255; % Find differences from a frame to background, which are most fly pixels
            Diff=bwareaopen(Diff,C1); % remove objects smaller than threshold C1
            for ncol = 1:Ncolumn
                for nrow = 1:Nrow
                    TubeEdgeX=int16(TubeEdgeX); TubeEdgeY=int16(TubeEdgeY); nrow=int16(nrow); ncol=int16(ncol);

                    [Y,X]=find(Diff(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1)==1); % Locate each fly pixel
                    FlyPixels=find(Diff(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1)==1);
                    SizeofFly(nrow,ncol,index1)=length(FlyPixels);
                    CurrentTube=CurrentFrame(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1); % Region of one curent tube
                    CurrentTubeIntensity=CurrentTube(FlyPixels);
                    MedianIntensity=median(CurrentTubeIntensity(:)); % Median of grayscales of all fly pixels, used for splitting periphery and core of a fly
                    
                    PreviousPeriphery(nrow,ncol,:,:)=CurrentPeriphery(nrow,ncol,:,:);  
                    PreviousCore(nrow,ncol,:,:)=CurrentCore(nrow,ncol,:,:); % Keep periphery and core of prevvious frame before extract them from current frame
                    
             %-----Split periphery and core based on median grayscale of each fly--------------
                    CurrentPeriphery(nrow,ncol,:,:)=zeros(TubeArea);
                    CurrentCore(nrow,ncol,:,:)=zeros(TubeArea);
                    FlyPixels1=sub2ind(size(CurrentPeriphery),repmat(nrow,SizeofFly(nrow,ncol,index1),1),repmat(ncol,SizeofFly(nrow,ncol,index1),1),Y,X);
                    CurrentPeriphery(FlyPixels1)= CurrentTube(FlyPixels);
                    CurrentCore(FlyPixels1)=CurrentTube(FlyPixels);
                    CurrentPeriphery(nrow,ncol,CurrentPeriphery(nrow,ncol,:,:)<MedianIntensity)=0;
                    CurrentCore(nrow,ncol,CurrentCore(nrow,ncol,:,:)>MedianIntensity)=0;
                    CurrentPeriphery(nrow,ncol,CurrentPeriphery(nrow,ncol,:,:)~=0)=1;
                    CurrentCore(nrow,ncol,CurrentCore(nrow,ncol,:,:)~=0)=1;
             %----------------------------------------------------------------------------------       
                    PeripheryMovement(nrow,ncol,index1)=length(find((PreviousPeriphery(nrow,ncol,:,:)+CurrentPeriphery(nrow,ncol,:,:))==1)); 
                    %Find PM by comparing periphery parts from previous frame and from current frame  
                    CoreMovement(nrow,ncol,index1)=length(find((PreviousCore(nrow,ncol,:,:)+CurrentCore(nrow,ncol,:,:))==1));
                    %Find CM
                    
                    Xposition(nrow,ncol,index1)=mean(X)+TubeEdgeX(ncol)-1;
                    Yposition(nrow,ncol,index1)=mean(Y)+TubeEdgeY(nrow)-1;
%                     Diff(Yposition(nrow,ncol,index1)-15:Yposition(nrow,ncol,index1)+15,Xposition(nrow,ncol,index1)-3:Xposition(nrow,ncol,index1)+3)=255;
%                     Diff(Yposition(nrow,ncol,index1)-3:Yposition(nrow,ncol,index1)+3,Xposition(nrow,ncol,index1)-10:Xposition(nrow,ncol,index1)+10)=255;
                end
            end
%             figure(1)
%             all=CurrentTube;
%             all(end+1:end+Yinterval,:)=CurrentPeriphery(nrow,ncol,:,:);
%             all(end+1:end+Yinterval,:)=CurrentCore(nrow,ncol,:,:);
%             all(end+1:end+Yinterval,:)=PreviousPeriphery(nrow,ncol,:,:);
%             all(end+1:end+Yinterval,:)=PreviousCore(nrow,ncol,:,:);
%             imshow(all)
        end
    end
    

TrainingCD=[];
TrainingPM=[];
TrainingCM=[];
traininglabel=[];
trainingdata=[];

%---------Extract normalized features and save as individual .txt files for each fly
for ncol=1:Ncolumn 
    for nrow=1:Nrow  
        [Features,normXposition]=features(SizeofFly(nrow,ncol,:),Xposition(nrow,ncol,:),PeripheryMovement(nrow,ncol,:),CoreMovement(nrow,ncol,:));
        fid=fopen([SavePath  '\CentralDisplacement' num2str(ncol) num2str(nrow) '.txt'],'w');
        fprintf(fid,'%.3f\n',Features(:,1));
        fclose(fid);
        fid=fopen([SavePath '\PeripheryMovement' num2str(ncol) num2str(nrow) '.txt'],'w');
        fprintf(fid,'%.3f\n',Features(:,2));
        fclose(fid);
        fid=fopen([SavePath '\CoreMovement' num2str(ncol) num2str(nrow) '.txt'],'w');
        fprintf(fid,'%.3f\n',Features(:,3));
        fclose(fid);
    end
end
%-------------------------------------------------------------------

timenow=datestr(now,0);
disp([timenow 'Extracting features. Progress : 100%' ])
    
%---------pick out features of labeled grooming frames as training samples----
fidin=fopen(GroomingFile); % open file with manually labeled time intervals of grooming                       
while ~feof(fidin)   
    tline=fgetl(fidin);   
    if length(tline) ~= 0 && tline(1) ~= '[' %read fly number from lines do not start at '['
        flynum = str2num(tline)
        fid=fopen([SavePath  '\CentralDisplacement' num2str(flynum) '.txt'],'r');
        [CD,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\PeripheryMovement' num2str(flynum) '.txt'],'r');
        [PM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\CoreMovement' num2str(flynum) '.txt'],'r');
        [CM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        
    elseif length(tline) ~= 0 && tline(1) == '[' %read time for behaviors from lines start at '['     
        timeindex=regexp(tline,'\d+','match');
        startmin=str2num(cell2mat(timeindex(1)));
        startsec=str2num(cell2mat(timeindex(2)));
        endmin=str2num(cell2mat(timeindex(3)));
        endsec=str2num(cell2mat(timeindex(4)));
        frameinterval=[(startmin*60+startsec)*AnalyzingRate+1:(endmin*60+endsec)*AnalyzingRate];
        TrainingCD(end+1:end+length(frameinterval))=CD(frameinterval);
        TrainingPM(end+1:end+length(frameinterval))=PM(frameinterval);
        TrainingCM(end+1:end+length(frameinterval))=CM(frameinterval);
    end
end
fclose(fidin)
traininglabel(end+1:length(TrainingCD),1)=1;

%---------pick out features of labeled locomotion frames as training samples----
fidin=fopen(LocomotionFile);                        
while ~feof(fidin)                                              
    tline=fgetl(fidin);                               
    if length(tline) ~= 0 && tline(1)~= '['
        flynum = str2num(tline)
        fid=fopen([SavePath  '\CentralDisplacement' num2str(flynum) '.txt'],'r');
        [CD,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\PeripheryMovement' num2str(flynum) '.txt'],'r');
        [PM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\CoreMovement' num2str(flynum) '.txt'],'r');
        [CM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        
    elseif length(tline) ~= 0 && tline(1) == '['        
        timeindex=regexp(tline,'\d+','match');
        startmin=str2num(cell2mat(timeindex(1)));
        startsec=str2num(cell2mat(timeindex(2)));
        endmin=str2num(cell2mat(timeindex(3)));
        endsec=str2num(cell2mat(timeindex(4)));
        frameinterval=[(startmin*60+startsec)*AnalyzingRate+1:(endmin*60+endsec)*AnalyzingRate];
        TrainingCD(end+1:end+length(frameinterval))=CD(frameinterval);
        TrainingPM(end+1:end+length(frameinterval))=PM(frameinterval);
        TrainingCM(end+1:end+length(frameinterval))=CM(frameinterval);
    end
end
fclose(fidin)
traininglabel(end+1:length(TrainingCD))=2;

%---------pick out features of labeled resting frames as training samples----
fidin=fopen(RestingFile);                        
while ~feof(fidin)                                              
    tline=fgetl(fidin);                               
    if length(tline) ~= 0 && tline(1)~= '['
        flynum = str2num(tline)
        fid=fopen([SavePath  '\CentralDisplacement' num2str(flynum) '.txt'],'r');
        [CD,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\PeripheryMovement' num2str(flynum) '.txt'],'r');
        [PM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        fid=fopen([SavePath '\CoreMovement' num2str(flynum) '.txt'],'r');
        [CM,count]=fscanf(fid,'%f',inf);
        fclose(fid);
        
    elseif length(tline) ~= 0 && tline(1) == '['        
        timeindex=regexp(tline,'\d+','match');
        startmin=str2num(cell2mat(timeindex(1)));
        startsec=str2num(cell2mat(timeindex(2)));
        endmin=str2num(cell2mat(timeindex(3)));
        endsec=str2num(cell2mat(timeindex(4)));
        frameinterval=[(startmin*60+startsec)*AnalyzingRate+1:(endmin*60+endsec)*AnalyzingRate];
        TrainingCD(end+1:end+length(frameinterval))=CD(frameinterval);
        TrainingPM(end+1:end+length(frameinterval))=PM(frameinterval);
        TrainingCM(end+1:end+length(frameinterval))=CM(frameinterval);
    end
end
fclose(fidin)
traininglabel(end+1:length(TrainingCD))=3;
%--------------------------------------------------------------------


traininglabel(find(TrainingCD+TrainingPM+TrainingCM==0))=3; %frames with 3 features equal to 0 are labeled as resting 
trainingdata(:,1)=TrainingCD;
trainingdata(:,2)=TrainingPM;
trainingdata(:,3)=TrainingCM;
save([TrainingFilePath, '\GroomTrainlabel.mat'],'traininglabel');
save([TrainingFilePath, '\GroomTrainfeature.mat'],'trainingdata');

timenow=datestr(now,0);
disp([timenow ' Training features saved to ' '"' SavePath '"'])
disp([timenow ' Finished analysing']) 
end


function [Features,normXposition] = features(SizeofFly,Xpositionindi,PeripheryMovementindi,CoreMovementindi)
    % Format and normalize features and positions
    % Inputs: 
    % SizeofFly,Xposition,PeripheryMovement,CoreMovement - Sizes, horizontal positions, PM and CM of all flies in video
    % Output:
    % Features - N by 3 matrix,columns represent normalized features CD, PM, and CM from left to right, respectively.
    %           Each row represents features of a fly in one frame,
    % normXposition - Xposition normalized by linear size of fly
    MedianSize=median(SizeofFly(SizeofFly>0));
    Scale=sqrt(MedianSize);
    
    [normXposition,dxposition]=Filtering(Xpositionindi); % Preprocess position and displacement
    normXposition=normXposition/Scale;
    CD=dxposition/Scale; 
    
    PM=PeripheryMovementindi;
    PM=sqrt(PM);
    PM=PM./Scale;
    
    CM=CoreMovementindi;
    CM=sqrt(CM);
    CM=CM./Scale;
 
    Features=zeros(length(CD),3);
    Features(:,1)=CD;
    Features(:,2)=PM;
    Features(:,3)=CM;
end

function [Position,Displacement]=Filtering(Xposition)
    % Fill missing data points and compute displacement
    % Inputs: 
    % Xposition - Time series of positions of a fly
    % Output:
    % Position - Position after missing data filled
    % Displacement - Displacement between consecutive frames
    nof=length(Xposition);
    n=1;
    if Xposition(1)==0
        while Xposition(n)==0 & n<length(Xposition)
            n=n+1;
        end
        Xposition(1:n-1)=Xposition(n);
    end

    for i=n:nof
       if Xposition(i)==0
           Xposition(i)=Xposition(i-1);
       end
    end
    
    Displacement(2:nof)=abs(Xposition(2:nof)-Xposition(1:(nof-1)));
    Displacement(1)=Displacement(2);
    Position=Xposition;
end
