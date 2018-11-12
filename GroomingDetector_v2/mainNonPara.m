function mainPara(Xinitial,Xinterval,Yinitial,Yinterval,fullname,NumberofFiles,savepathname)
    % Analyzing videos, extract features, classify behaviors into grooming,
    % locomotion, and rest and save positions and grooming events to .txt
    % files
    % Inputs: 
    % Xinitial, Yinitial - Left and top boundaries of regions of interest from videos, defined by sliders in 'GroomingDetector' GUI
    % Xinterval, Yinterval - Horizontal and vertical intervals to segment tubes, defined by sliders in 'GroomingDetector' GUI
    % fullname - input video paths and names
    % NumberofFiles - Number of input videos
    % savepathname - Path to save output data
    
   % ------ Configure the analysis ---------------------------------------
    Parameters = load('Parameters');
    C0 = Parameters.C0;
    C1 = Parameters.C1;
    BackgroundRate = Parameters.BackgroundRate;
    KNeighbors = Parameters.KNeighbors;
    NumberofContrast = Parameters.NumberofContrast;
    FrameRate = Parameters.FrameRate;
    AnalyzingRate = Parameters.AnalyzingRate;
    Nrow = Parameters.Nrow;
    Ncolumn = Parameters.Ncolumn;
    TransVideo = Parameters.TransVideo;

    BackgroundUpdate = BackgroundRate*60*FrameRate; %Update background every 'BackgroundUpadate' frames. Set in 'Setting Parameters > Advanced Setting'
    AnalyzingStep=FrameRate/AnalyzingRate; % Step size to analyze the video. To analyze all frames, FrameRate = AnalyzingRate. Set in 'Setting Parameters'
   %----------------------------------------------------------------------
    

    ['Initializing......']
    for nfile=1:NumberofFiles
       % ------ getting video information---------------------------------
        [~,savename,~]=fileparts(char(fullname(nfile)));
        savefilename=[savepathname '\' savename];
        mkdir(savefilename);
        mov=VideoReader(char(fullname(nfile))); % Creat movie object
        TimeInterval = 1/mov.FrameRate;
        Duration = mov.Duration;
        Framesize=[mov.Height,mov.Width];
        if TransVideo==1
            Framesize=flip(Framesize); 
        end
       % -----------------------------------------------------------------

        Xposition=[]; % Output horizontal positions of all flies through a video
        Yposition=[]; % Vertical positions
        PeripheryMovement=[]; % Feature PM
        CoreMovement=[]; % Feature CM
        FlyPixels = [];
        SizeofFly = [];

        timenow=datestr(now,0);
        disp([timenow ' Processing video ' '"' savename '"'])
        disp([timenow ' Generating background'])
        NBackground = ceil(Duration/BackgroundUpdate*FrameRate);
        BackgroundSet = uint8(zeros(Framesize(1),Framesize(2),NBackground));
        mov.CurrentTime = 0;  
        
       % ------ setting background ---------------------------------------
        for nBG = 1:NBackground
            index = BackgroundUpdate*(nBG-1)+1;
            mov.CurrentTime = TimeInterval*index;
            TemplateFrame=rgb2gray(readFrame(mov));
            if TransVideo==1
                TemplateFrame=TemplateFrame';
            end
            Ncontrast=floor(linspace(index,min(BackgroundUpdate*nBG,mov.Duration/TimeInterval),NumberofContrast+2));
            for j=2:NumberofContrast-1
                index = Ncontrast(j);
                mov.CurrentTime = TimeInterval*index;
                ContrastFrame=rgb2gray(readFrame(mov));
                if TransVideo==1
                    ContrastFrame=ContrastFrame';
                end
                TemplateFrame(ContrastFrame-TemplateFrame>=C0)=ContrastFrame(ContrastFrame-TemplateFrame>=C0);% Compare TemplateFrame with each ContrastFrame to create a background
            end
            BackgroundSet(:,:,nBG)=TemplateFrame;
        end
       % ------ Background set created ------------------------------------  

       % ------ Extract fly positions, sizes and features every AnalyzingStep frames------------
        disp([timenow ' Analyzing behaviors'])
        processingstage=0;
        CurrentFrame=zeros(Framesize);
        CurrentPeriphery=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % PM in current frame
        CurrentCore=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % CM in current frame
        PreviousPeriphery=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % PM in previous frame
        PreviousCore=zeros(Nrow,Ncolumn,int16(Yinterval),int16(Xinterval)); % CM in previous frame
        TubeEdgeX = [Xinitial:Xinterval:Xinitial+Ncolumn*Xinterval]; %Boundaries of each tube, set by sliders in 'GroomingDetector' panel
        TubeEdgeY = [Yinitial:Yinterval:Yinitial+Nrow*Yinterval];
        TubeArea = int16([Yinterval,Xinterval]); % Dimension of area for each tube

        mov.CurrentTime = 0;
        index1=0;
        while hasFrame(mov)
            if mov.CurrentTime>Duration*processingstage/100
                disp(['Progress : ' num2str(processingstage) '%' ])
                processingstage=processingstage+10;    
            end
            CurrentFrame=rgb2gray(readFrame(mov));

            index1=index1+1;
            CurrentBG = BackgroundSet(:,:,floor(mov.CurrentTime/BackgroundUpdate*FrameRate)+1); % pick the background from background set for current frame

            if TransVideo==1
                CurrentFrame=CurrentFrame';
            end
            Diff = uint8(zeros(size(CurrentFrame)));
            Diff(CurrentBG - CurrentFrame >= C0) = 1; % Find objects that are different from background filterred by threshold C0
            Diff=bwareaopen(Diff,C1,4); % remove objects smaller than threshold C1
            CC = bwconncomp(Diff,4);
            stats = regionprops(CC,'MajorAxisLength','MinorAxisLength');
            OverSize = find([stats.MajorAxisLength]./[stats.MinorAxisLength]>3);
            for nOverSize=1:length(OverSize)
                Diff(CC.PixelIdxList{OverSize(nOverSize)})=0;  % remove objects of which sizes are unlikely to be flies
            end
            for ncol = 1:Ncolumn
                for nrow = 1:Nrow
                    TubeEdgeX=int16(TubeEdgeX); TubeEdgeY=int16(TubeEdgeY); nrow=int16(nrow); ncol=int16(ncol);
                    [Y,X]=find(Diff(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1)==1); % Locate each fly pixel
                    Xposition(nrow,ncol,index1)=mean(X)+double(TubeEdgeX(ncol))-1;
                    Yposition(nrow,ncol,index1)=mean(Y)+double(TubeEdgeY(nrow))-1;

                    FlyPixels=find(Diff(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1)==1); % Pixels of a fly within current tube
                    SizeofFly(nrow,ncol,index1)=length(FlyPixels);
                    CurrentTube=CurrentFrame(TubeEdgeY(nrow):TubeEdgeY(nrow+1)-1,TubeEdgeX(ncol):TubeEdgeX(ncol+1)-1); % Region of one curent tube
                    CurrentTubeIntensity=CurrentTube(FlyPixels);
                    MedianIntensity=median(CurrentTubeIntensity(:)); % Median of grayscales of all fly pixels, used for splitting periphery and core of a fly
                    PreviousPeriphery(nrow,ncol,:,:)=CurrentPeriphery(nrow,ncol,:,:);  
                    PreviousCore(nrow,ncol,:,:)=CurrentCore(nrow,ncol,:,:); % Keep periphery and core of previous frame before extract them from current frame

                 %-----Split periphery and core based on median grayscale of each fly--------------
                    CurrentPeriphery(nrow,ncol,:,:)=zeros(TubeArea);
                    CurrentCore(nrow,ncol,:,:)=zeros(TubeArea); CurrentCore(nrow,ncol,:,:)=255;
                    FlyPixels1=sub2ind(size(CurrentPeriphery),repmat(nrow,SizeofFly(nrow,ncol,index1),1),repmat(ncol,SizeofFly(nrow,ncol,index1),1),Y,X);
                    CurrentPeriphery(FlyPixels1)= CurrentTube(FlyPixels);
                    CurrentCore(FlyPixels1)=CurrentTube(FlyPixels);
                    CurrentPeriphery(nrow,ncol,CurrentPeriphery(nrow,ncol,:,:)<MedianIntensity)=0;
                    CurrentCore(nrow,ncol,CurrentCore(nrow,ncol,:,:)>=MedianIntensity)=255;
                    CurrentPeriphery(nrow,ncol,CurrentPeriphery(nrow,ncol,:,:)~=0)=1;
                    CurrentCore(nrow,ncol,CurrentCore(nrow,ncol,:,:)~=255)=1;
                    CurrentCore(nrow,ncol,CurrentCore(nrow,ncol,:,:)==255)=0;
                 %----------------------------------------------------------------------------------       
                    PeripheryMovement(nrow,ncol,index1)=length(find((PreviousPeriphery(nrow,ncol,:,:)+CurrentPeriphery(nrow,ncol,:,:))==1)); 
                    CoreMovement(nrow,ncol,index1)=length(find((PreviousCore(nrow,ncol,:,:)+CurrentCore(nrow,ncol,:,:))==1));

                end
            end

            try
                for skipframe=1:AnalyzingStep-1
                    readFrame(mov); 
                end
            end
        end 
        disp(['Extracting features. Progress : 100%' ])

        timenow=datestr(now,0);
        disp([timenow ' Saving locomotion......'])
        savedata(savefilename,Ncolumn,Nrow,Xposition,Yposition); % Save positions of flies through a video

        timenow=datestr(now,0);
        disp([timenow ' Detecting grooming......'])
        KNNClassifier(savefilename,KNeighbors,AnalyzingRate,SizeofFly,Xposition,PeripheryMovement,CoreMovement,Ncolumn,Nrow); % Classifiy behaviors and save

        timenow=datestr(now,0);
        disp([timenow ' Data saved to ' '"' savefilename '"'])
        disp([timenow ' Finished analysing ' '"' savename '"']) 
    end
end

function KNNClassifier(savefilename,KNeighbors,AnalyzingRate,SizeofFly,Xposition,PeripheryMovement,CoreMovement,Ncolumn,Nrow)
    % Classify behaviors, represented by PeripheryMovement, CoreMovement
    % and Central displacement, into grooming, locomotion and rest based on
    % a k-nearest neighbors (kNN) method
    % Inputs: 
    % savefilename - file to save output grooming data
    % KNeighbors - # of neighbors in kNN
    % AnalyzingRate - Rate to analyze viode, in frames per second
    % OutputNframe - Total # of frames to classify
    % SizeofFly,Xposition,PeripheryMovement,CoreMovement - Sizes, horizontal positions, PM and CM of all flies in video
    % Ncolumn,Nrow - # of rows and columns of tubes
    load GroomTrainlabel;
    load GroomTrainfeature; % Load training set
    Mdl = fitcknn(trainingdata,traininglabel,'NumNeighbors',KNeighbors);
    OutputNframe = length(Xposition);
    for ncol=1:Ncolumn
        for nrow=1:Nrow
            [Features,normXposition]=features(SizeofFly(nrow,ncol,:),Xposition(nrow,ncol,:),PeripheryMovement(nrow,ncol,:),CoreMovement(nrow,ncol,:));
            % Format and normalize features and positions of a current fly in each frame
            RawLabel = predict(Mdl,Features); % classify each frame with kNN based on normalized features 

            Grooming=zeros(1,OutputNframe);
            Locomotion=zeros(1,OutputNframe);
            Rest=zeros(1,OutputNframe);

            Grooming(find(RawLabel==1 | RawLabel==2))=1;
            Locomotion(find(RawLabel==3))=1;
            Rest(find(RawLabel==4))=1;

            normXposition(end:OutputNframe)=normXposition(end);
            normdxposition=Features(:,1);
            normdxposition(end:OutputNframe)=normdxposition(end);

            edge=zeros(1,OutputNframe);
            edge(find(normXposition>max(normXposition)-1.5 | normXposition<min(normXposition)+1.5))=1; % 
            Grooming(edge==1)=0; % ignore grooming behaviors when a fly is very close to food.

      %-------Prune raw grooming result----------------------
            window1=AnalyzingRate*3; % Filter 1, 3 seconds wide
            window2=AnalyzingRate*2; % Filter 2, 2 seconds wide
            FinalGrooming=zeros(1,OutputNframe);
            for i=1:OutputNframe-window1
%                 if sum(Grooming(i:i+window1))>window1*0.75 & sum(normdxposition(i:i+window1))<0.5
                if sum(Grooming(i:i+window1))>window1*0.75
                    FinalGrooming(i:i+window1)=Grooming(i:i+window1); 
                    % Within three seconds, if more than 80% frames are labeled as grooming and meanwhile the fly moves less
                    % than 0.5 body length, then grooming labels are confirmed
                end
            end
            GroomingTime=find(FinalGrooming==1);
            for i=2:length(GroomingTime)
                if GroomingTime(i)-GroomingTime(i-1)<window2 
                    FinalGrooming(GroomingTime(i-1):GroomingTime(i))=1;
                    % Fill gaps shorter than  2 seconds
                end
            end
      %---------------------------------------------------------    
            fid=fopen([savefilename '\grooming_'  num2str(ncol) num2str(nrow) '.txt'],'w');
            fprintf(fid,'%10d\n',FinalGrooming); % Save grooming data
            fclose(fid);
        end
    end
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
    
    CD=reshape(CD,[length(CD),1]);
    PM=reshape(PM,[length(PM),1]);
    CM=reshape(CM,[length(CM),1]);
 
    Features=zeros(length(CD),3);
    Features(:,1)=CD;
    Features(:,2)=PM;
    Features(:,3)=CM;
end

function savedata(savefilename,Ncolumn,Nrow,Xposition,Yposition)
    % Save Xpositions and Ypositions of flies
    % Inputs: 
    % savefilename - file to save output grooming data
    % Ncolumn,Nrow - # of rows and columns of tubes
    % Xposition, Yposition - Horizontal and Vertical positions of flies
    for ncol=1:Ncolumn
        for nrow=1:Nrow
            [Position,dxposition]=Filtering(Xposition(nrow,ncol,:)); % Fill missing data in Xposition
            fid=fopen([savefilename  '\Xposition' num2str(ncol) num2str(nrow) '.txt'],'w');
            fprintf(fid,'%.1f\n',Position);
            fclose(fid);
            
            [Position,dxposition]=Filtering(Yposition(nrow,ncol,:)); % Fill missing data in Yposition
            fid=fopen([savefilename '\Yposition' num2str(ncol) num2str(nrow) '.txt'],'w');
            fprintf(fid,'%.1f\n',Position);
            fclose(fid);
            
        end 
    end
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
    if isnan(Xposition(1))
        while isnan(Xposition(n)) & n<length(Xposition)
            n=n+1;
        end
        Xposition(1:n-1)=Xposition(n);
    end

    for i=n+1:nof
       if isnan(Xposition(i)) | abs(Xposition(i)-Xposition(i-1))>30
           Xposition(i)=Xposition(i-1);
       end
    end
    
    Displacement(2:nof)=abs(Xposition(2:nof)-Xposition(1:(nof-1)));
    Displacement(1)=Displacement(2);
    Displacement(Displacement<1)=0;
    Position=Xposition;
end
