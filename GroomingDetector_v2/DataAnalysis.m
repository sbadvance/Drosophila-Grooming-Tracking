clear all% function output=DataAnalysis();
%the output is a m*n*k matrice
%n is the number of time samples, m is number of flies,
%k=5, with 1 for grooming, 2 for locomotion, 3 for sleep, 4 for feeding, 5 for shourt rest
fph=5*60*60; %frames per hour of raw data
nfph=3; %bin data into nfph windows per hour
nFrame=8*fph; 
% ncol=2;nrow=14;foodDir=[0,1];flyofInterest=[1:15 17:28];%181021
ncol=2;nrow=16;foodDir=[0,1];flyofInterest=[1:nrow*ncol];%181027

targetfile1=uigetdir('pick the path of data');
folders=dir(targetfile1);
folders=folders(3:end);
for nf=1:length(folders)
    if folders(nf).isdir
        folderdir=[folders(nf).folder '\' folders(nf).name];
        nfly=0;
        for col=1:ncol
            for row=1:nrow
                nfly=nfly+1;
                grooming=dlmread([folderdir '\grooming_' num2str(col) num2str(row) '.txt']);
%                 grooming(grooming==1)=5;
                Xposition=dlmread([folderdir '\Xposition' num2str(col) num2str(row) '.txt']);
                Yposition=dlmread([folderdir '\Yposition' num2str(col) num2str(row) '.txt']);
                nonsense=find(Xposition==0);
                for i=1:length(nonsense)
                    Xposition(nonsense(i))=Xposition(nonsense(i)-1);
                    Yposition(nonsense(i))=Yposition(nonsense(i)-1);
                end
                PopulationXposition((nf-1)*nFrame+1:(nf-1)*nFrame+length(Xposition),nfly)=Xposition;
                PopulationXposition((nf-1)*nFrame+length(Xposition):nf*nFrame,nfly)=Xposition(end);
                PopulationLocomotion((nf-1)*nFrame+1:(nf-1)*nFrame+length(Xposition)-1,nfly)=abs(Xposition(2:end)-Xposition(1:end-1));
                PopulationLocomotion((nf-1)*nFrame+length(Xposition):nf*nFrame,nfly)=0;
                PopulationGrooming((nf-1)*nFrame+1:(nf-1)*nFrame+length(grooming),nfly)=grooming;
                PopulationGrooming((nf-1)*nFrame+length(grooming)+1:nf*nFrame,nfly)=0;
            end
        end
    end
end

nfly=0;
for fly=flyofInterest
    nfly=nfly+1;
    XX=PopulationXposition(:,fly);
    [Xposition,dxposition]=smoothing(XX);
    dxposition(dxposition<0.5)=0;
    loco=zeros(1,length(XX));
    loco(dxposition>0.5)=1;
        
    grooming=PopulationGrooming(:,fly);
    sleeptime=findsleep(Xposition,grooming,dxposition,fph);
    feedtime=findfeed(Xposition,dxposition,sleeptime,foodDir(ceil(fly/nrow)));
    loco(grooming==1)=0;
    loco(feedtime==1)=0;
    loco(sleeptime==1)=0;
    
    shortrest=ones(1,length(XX));
    shortrest(loco==1)=0;
    shortrest(grooming==1)=0;
    shortrest(sleeptime==1)=0;
    shortrest(feedtime==1)=0;
    
    
    [LOC,tt]=Bin(loco,fph,nfph);
    [GRO,tt]=Bin(grooming,fph,nfph);
    [SLP,tt]=Bin(sleeptime,fph,nfph);
    [FD,tt]=Bin(feedtime,fph,nfph);
    [REST,tt]=Bin(shortrest,fph,nfph);
    
    LOC=LOC/fph*nfph;
    GRO=GRO/fph*nfph;
    SLP=SLP/fph*nfph;
    FD=FD/fph*nfph;
    REST=REST/fph*nfph;
    LOCall(:,nfly)=LOC;
    GROall(:,nfly)=GRO;
    SLPall(:,nfly)=SLP;
    FDall(:,nfly)=FD;
    RESTall(:,nfly)=REST;
end

output(:,:,1)=GROall;
output(:,:,2)=LOCall;
output(:,:,3)=SLPall;
output(:,:,4)=FDall;
output(:,:,5)=RESTall;

t=[0:1/nfph:(size(LOCall,1)-1)/nfph];
figure()
plot(t,mean(GROall,2))
title('Average grooming')
xlabel('time (hours)')
ylabel('fraction of time')
figure()
plot(t,mean(LOCall,2))
title('Average locomotion')
xlabel('time (hours)')
ylabel('fraction of time')
figure()
plot(t,mean(SLPall,2))
title('Average sleep')
xlabel('time (hours)')
ylabel('fraction of time')
figure()
plot(t,mean(FDall,2))
title('Average feeding')
xlabel('time (hours)')
ylabel('fraction of time')
figure()
plot(t,mean(RESTall,2))
title('Average rest')
xlabel('time (hours)')
ylabel('fraction of time')


processData = reshape(mean(output,2),[size(output,1),5]);
nDays = ceil(size(output,1)/nfph/24);
for nd=1:nDays
    tblData(nd,:)=mean(processData((nd-1)*24*nfph+1:min(nd*24*nfph,size(output,1)),:),1);
    indDailyData(nd,:,:)=mean(output((nd-1)*24*nfph+1:min(nd*24*nfph,size(output,1)),:,:),1);
end

for nbehavior = 1:size(tblData,2)
    if nDays>1
        size(indDailyData(1,:,nbehavior));
        tblData(4,nbehavior)=meandiff(indDailyData(1,:,nbehavior),indDailyData(2,:,nbehavior));
        if nDays>2
            tblData(5,nbehavior)=meandiff(indDailyData(1,:,nbehavior),indDailyData(3,:,nbehavior));
            tblData(6,nbehavior)=meandiff(indDailyData(2,:,nbehavior),indDailyData(3,:,nbehavior));
        end
    end
end
colname={'Grooming' 'Locomotion' 'Sleep' 'Feed' 'Rest'};
rowname={'day1' 'day2' 'day3' 'pvalue_1vs2' 'pvalue_1vs3' 'pvalue_2vs3'};
figure()
uitable('Data',tblData,'ColumnName',colname,'RowName',rowname,'Position',[0 0 800 400],'ColumnWidth',{80 80 80},'FontSize',12);

