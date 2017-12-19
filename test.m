clear all
TrainingFilePath = uigetdir( 'selet the path of training files'); %select folder where training video and label files are

VideoFile=[TrainingFilePath,'\TrainingVideo.avi']; 
GroomingFile=[TrainingFilePath,'\LabeledGrooming.txt'];
LocomotionFile=[TrainingFilePath,'\LabeledLocomotion.txt'];
RestingFile=[TrainingFilePath,'\LabeledResting.txt'];
SavePath=[TrainingFilePath '\Features']; 

load('Parameters')
    

TrainingCD=[];
TrainingPM=[];
TrainingCM=[];
traininglabel=[];
trainingdata=[];
    
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
