function [y,dy]=smoothing(Yposition)
nof=length(Yposition);
n=1;
if Yposition(1)==0
    while Yposition(n)==0 & n<length(Yposition)
        n=n+1;
    end
    Yposition(1:n-1)=Yposition(n);
end

for i=n:nof
   if Yposition(i)==0
       Yposition(i)=Yposition(i-1);
   end
end
dyposition(2:nof)=abs(Yposition(2:nof)-Yposition(1:(nof-1)));
dyposition(1)=dyposition(2);

dy=dyposition;
y=Yposition;