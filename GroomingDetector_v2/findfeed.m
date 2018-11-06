function feedtime=findfeed(Xposition,dxposition,sleeptime,direction)
%direction=1 means food on left
%direction=0 means food on right
fps=5;
rawfeedtime=zeros(size(dxposition));
feedtime=zeros(size(dxposition));
if direction==0
    Xposition=max(Xposition)-Xposition;
end

Xmin=zeros(size(Xposition));
for t=1:fps*60*60*8:length(Xposition)
    Xmin(t:min(t+fps*60*60*8-1,end))=min(Xposition(t:min(t+fps*60*60*8-1,end)));
end

rawfeedtime(find((Xposition-Xmin)<15))=1;
rawfeedtime(sleeptime==1)=0;
% feedtime=rawfeedtime;
threshold2=fps*3;
n=0;
tnotfeed=find(rawfeedtime==0);
for i=1:length(tnotfeed)-1
    if tnotfeed(i+1)-tnotfeed(i)>threshold2
        n=n+1;
        feedtime(tnotfeed(i)+1:tnotfeed(i+1)-1)=1;
    end
end
    
    


