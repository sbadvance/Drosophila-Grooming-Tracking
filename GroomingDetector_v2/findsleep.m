function sleeptime=findsleep(Xposition,grooming,dxposition,fph)

ac=zeros(size(dxposition));
sleeptime=zeros(size(dxposition));

ac(dxposition>10)=1;
ac(grooming~=0)=1;
threshold1=fph/60*5;

n=0;
tactive=find(ac==1);
for i=1:length(tactive)-1
    if tactive(i+1)-tactive(i)>threshold1
        n=n+1;
        sleeptime(tactive(i)+1:tactive(i+1)-1)=1;
    end
end
    


