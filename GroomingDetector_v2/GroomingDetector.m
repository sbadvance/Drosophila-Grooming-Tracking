function varargout = GroomingDetector(varargin)
% GROOMINGDETECTOR MATLAB code for GroomingDetector.fig
%      GROOMINGDETECTOR, by itself, creates a new GROOMINGDETECTOR or raises the existing
%      singleton*.
%
%      H = GROOMINGDETECTOR returns the handle to a new GROOMINGDETECTOR or the handle to
%      the existing singleton*.
%
%      GROOMINGDETECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GROOMINGDETECTOR.M with the given input arguments.
%
%      GROOMINGDETECTOR('Property','Value',...) creates a new GROOMINGDETECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GroomingDetector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GroomingDetector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GroomingDetector

% Last Modified by GUIDE v2.5 20-Jul-2017 13:48:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GroomingDetector_OpeningFcn, ...
                   'gui_OutputFcn',  @GroomingDetector_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GroomingDetector is made visible.
function GroomingDetector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GroomingDetector (see VARARGIN)

% Choose default command line output for GroomingDetector
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --Load and initialzing parameters
global C0;
global C1;
global FrameRate;
global AnalyzingRate;
global Nrow;
global Ncolumn;
global TransVideo;
load('Parameters')
% UIWAIT makes GroomingDetector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GroomingDetector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% -- pushbutton--'Open video files'--select videos for analyzing
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mov;
global NumberofFiles;
global fullname;
[filename, pathname] = uigetfile('*.*', 'Pick a video','MultiSelect','on');

    if iscell(filename)
        NumberofFiles=length(filename);
    elseif filename ~= 0
        NumberofFiles = 1;
        filename=mat2cell(filename,1);
    else
        NumberofFiles = 0;
        return
    end
    fullname = strcat(pathname,filename);
    set(handles.text3,'string',['Video files:',filename]); 
    set(handles.text2,'string','Loadinging videos');
    mov=VideoReader(char(fullname(1)));
%     Nframe=get(mov, 'NumberOfFrames');
    set(handles.text2,'string','Videos loaded');


% --- Text box for displaying video opening status
function text2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Text boxe for displaying name of selected video files
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% -- pushbutton--'Save as'--Select path to save output data.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global savepathname;
savepathname = uigetdir( 'pick a file to save data');


% -- pushbutton--'Preview'--Preview a sample frame of loaded viodes
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mov;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
global Xend;
global Yend;
global Nrow;
global Ncolumn;
global TransVideo;
mov.CurrentTime = 0;
SampleFrame = readFrame(mov);
SampleFrame = rgb2gray(SampleFrame);
if TransVideo==1
    SampleFrame=SampleFrame';
end
ResolVideo = size(SampleFrame);
Xend=ResolVideo(2);
Yend=ResolVideo(1);
Yinterval=floor(Yend/30);
Yinitial=1;
Xinterval=floor(Xend/4);
Xinitial=1;
    for yn=1:1:Nrow+1
        if Yinitial+(yn-1)*Yinterval+1<Yend-1
             SampleFrame(Yinitial+(yn-1)*Yinterval:Yinitial+(yn-1)*Yinterval+1,Xinitial:min(Xend,Xinitial+Ncolumn*Xinterval))=255;
        end
    end
    for xn=1:1:Ncolumn+1
        if Xinitial+(xn-1)*Xinterval+1<Xend-1
             SampleFrame(Yinitial:min(Yend,Yinitial+Nrow*Yinterval),Xinitial+(xn-1)*Xinterval:Xinitial+(xn-1)*Xinterval+1)=255;
        end
    end
axes(handles.axes1); 
imshow(SampleFrame);


% % -- pushbutton--'Setting parameters'-- Open paremeter setting GUI
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SetParameters;


% Axes1 for plotting sample frame of videos
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1


% Slider1- Adjust initial position of first tube from top
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global mov;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
global Xend;
global Yend;
global Nrow;
global Ncolumn;
global TransVideo;
SliderVal=get(hObject,'Value');
Yinitial=floor(SliderVal*Yend-1)+1;
mov.CurrentTime = 0;
SampleFrame = readFrame(mov);
SampleFrame = rgb2gray(SampleFrame);
if TransVideo==1
    SampleFrame=SampleFrame';
end

    for yn=1:1:Nrow+1
        if Yinitial+(yn-1)*Yinterval+1<Yend-1
             SampleFrame(Yinitial+(yn-1)*Yinterval:Yinitial+(yn-1)*Yinterval+1,Xinitial:min(Xend,Xinitial+Ncolumn*Xinterval))=255;
             set(handles.text8,'string','');
        end
        if Yinitial+(yn-1)*Yinterval+1>=Yend-1
            set(handles.text8,'string','lines out of image');
        end
    end

axes(handles.axes1); 
imshow(SampleFrame);

% 
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% Slider2- Adjust width of tubes 
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global mov;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
global Xend;
global Yend;
global Nrow;
global Ncolumn;
global TransVideo;
SliderVal=get(hObject,'Value');
Yinterval=floor(SliderVal*(Yend-Yinitial)/Nrow)+floor(Yend/30);
mov.CurrentTime = 0;
SampleFrame = readFrame(mov);
SampleFrame = rgb2gray(SampleFrame);
if TransVideo==1
    SampleFrame=SampleFrame';
end

    for yn=1:1:Nrow+1
        if Yinitial+(yn-1)*Yinterval+1<Yend-1
             SampleFrame(Yinitial+(yn-1)*Yinterval:Yinitial+(yn-1)*Yinterval+1,Xinitial:min(Xend,Xinitial+Ncolumn*Xinterval))=255;
             set(handles.text8,'string','');
        end
        if Yinitial+(yn-1)*Yinterval+1>=Yend-1
            set(handles.text8,'string','lines out of image');
        end
    end

axes(handles.axes1); 
imshow(SampleFrame);


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% Slider1- Adjust initial position of tubes from left
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global mov;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
global Xend;
global Yend;
global Nrow;
global Ncolumn;
global TransVideo;
SliderVal=get(hObject,'Value');
Xinitial=floor(SliderVal*Xend*0.3)+1;

mov.CurrentTime = 0;
SampleFrame = readFrame(mov);
SampleFrame = rgb2gray(SampleFrame);
if TransVideo==1
    SampleFrame=SampleFrame';
end

    for yn=1:1:Nrow+1
        if Yinitial+(yn-1)*Yinterval+1<Yend-1
             SampleFrame(Yinitial+(yn-1)*Yinterval:Yinitial+(yn-1)*Yinterval+1,Xinitial:min(Xend,Xinitial+Ncolumn*Xinterval))=255;
        end
    end
    for xn=1:1:Ncolumn+1
        if Xinitial+(xn-1)*Xinterval+1<Xend-1
             SampleFrame(Yinitial:min(Yend,Yinitial+Nrow*Yinterval),Xinitial+(xn-1)*Xinterval:Xinitial+(xn-1)*Xinterval+1)=255;
             set(handles.text8,'string','');
        end
        if Xinitial+(xn-1)*Xinterval+1>=Xend-1
            set(handles.text8,'string','lines out of image');
        end
    end
axes(handles.axes1); 
imshow(SampleFrame);

% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% Slider4- Adjust length of tubes 
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global mov;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
global Xend;
global Yend;
global Nrow;
global Ncolumn;
global TransVideo;
SliderVal=get(hObject,'Value');
Xinterval=floor(SliderVal*(Xend-Xinitial)/Ncolumn)+floor(Xend/4);

mov.CurrentTime = 0;
SampleFrame = readFrame(mov);
SampleFrame = rgb2gray(SampleFrame);
if TransVideo==1
    SampleFrame=SampleFrame';
end

    for yn=1:1:Nrow+1
        if Yinitial+(yn-1)*Yinterval+1<Yend-1
             SampleFrame(Yinitial+(yn-1)*Yinterval:Yinitial+(yn-1)*Yinterval+1,Xinitial:min(Xend,Xinitial+Ncolumn*Xinterval))=255;
        end
    end
    for xn=1:1:Ncolumn+1
        if Xinitial+(xn-1)*Xinterval+1<Xend-1
             SampleFrame(Yinitial:min(Yend,Yinitial+Nrow*Yinterval),Xinitial+(xn-1)*Xinterval:Xinitial+(xn-1)*Xinterval+1)=255;
             set(handles.text8,'string','');
        end
        if Xinitial+(xn-1)*Xinterval+1>=Xend-1
            set(handles.text8,'string','lines out of image');
        end
    end
axes(handles.axes1); 
imshow(SampleFrame);


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global NumberofFiles;
global fullname;
global savepathname;
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
main(Xinitial,Xinterval,Yinitial,Yinterval,fullname,NumberofFiles,savepathname)

% --- Executes during object creation, after setting all properties.
function text8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function pushbutton1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function pushbutton2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function pushbutton3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function pushbutton4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Yinterval;
global Xinterval;
global Yinitial;
global Xinitial;
SetTrainingSamples(Xinitial,Xinterval,Yinitial,Yinterval);
