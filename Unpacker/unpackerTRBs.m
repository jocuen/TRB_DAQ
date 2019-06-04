function unpackerTRBs(varargin)
% Read data from a TRB file
%
% unpackerTRB(filename,numberOfBitsToRead,pathIn,pathOut)
%
%- extension .hld is assumed if filename doesn't have extension.
%  Only . in the extension is assumed as the file doesn�t have extension.
%- numberOfBitsToRead are the amount of bits to read 10e6 creates a file
%  close to 100MB
%- pathOut is opcional and = to pathIn if is not include.
%
%
%
% This is the adaptation of unpackerTRBv2 to readout the group of 2 TRB
% used on the cosmic ray test to evaluate the performaces of the sectors


filename=varargin(1);
ext =cell(1);

I=find(filename{1} == '.'); ext{1} = '.hld';

if I
    if(length(filename{1}) == I)
        ext{1} = [];
    else
        ext{1} = filename{1}(I:end);
    end

    filename{1} = filename{1}(1:I-1);
end

numberOfBitsToRead = varargin{2};% A good number for this is 10000000
pathIn                  = varargin(3);
pathOut                 = varargin(4);
refTime                 = varargin{5};
INLCorrectionActive     = varargin{6}{1};

if INLCorrectionActive
INLParameters           = varargin{6}{2};
end

%%% HEX   DEC TRBAlias Det   TRBID
%%% 339   825 3        R3B    25 From GSI
%%% 364   868 3        R3B    68 From GSI
%%% 378   888 2        Auger  88 
%%% 37d   893 3        R3B    93
%%% 347   839 3        R3B    39 Diego Board
%%% 357   855 1        R3B    55 From Michael  
%%% 366   870 1        R3B    70 From Michael
%%% 378   888 1        R3B    88 From Michael
%%% 343   835 1        R3B    88 From Michael


TRBIds   = varargin{7}{1};  %id:    0x00000343 id:    0x00000346
%In Hex     339 346
TRBAlias = varargin{7}{2};

%         Data structure
%         size: 0x00000020  decoding: 0x00030001  id:    0x00010002  seqNr:  0x00000000
%         date: 2013-08-01  time:     13:57:11    runNr: 0x0a73dd37  expId:
% 
%         size: 0x0000015c  decoding: 0x00030001  id:    0x00002000  seqNr:  0x00000001
%         date: 2013-08-01  time:     13:57:11    runNr: 0x0a73dd37  expId:
%         size: 0x00000064  decoding: 0x00020001  id:    0x00000343  trigNr: 0x00000000
% 
%         00000000:  0x01000015  0x00000003  0x00000000  0x00000000
%         00000010:  0x00000000  0x2000087b  0x40f82bbb  0x50f83133
%         00000020:  0x30000004  0x210002a5  0x41f82bba  0x51f83132
%         00000030:  0x31000004  0x220001f8  0x42f82bb9  0x52f83131
%         00000040:  0x32000004  0x2300041d  0x43f82bba  0x53f83132
%         00000050:  0x33000004
%         size: 0x000000d4  decoding: 0x00020001  id:    0x00000346  trigNr: 0x00000000
% 
%         00000000:  0x01000031  0x00000003  0x00000000  0x3c95d4cf
%         00000010:  0x003f003f  0x20000f59  0x4008275e  0x40f82c0f
%         00000020:  0x50082ae4  0x50f83188  0x30000006  0x2100072f
%         00000030:  0x41f82c0f  0x51f83187  0x31000004  0x220005df
%         00000040:  0x523802be  0x42f82c0b  0x521003e8  0x527802ca
%         00000050:  0x52f83184  0x423805ab  0x52580150  0x52100431
%         00000060:  0x427805bb  0x52380b5e  0x425806f5  0x52100497
%         00000070:  0x52780b50  0x42380e09  0x52580a30  0x523814db
%         00000080:  0x42780dfc  0x52381525  0x42580ff9  0x4238160a
%         00000090:  0x527814d5  0x423816b1  0x52581254  0x52781542
%         000000a0:  0x52581904  0x427815fd  0x425819f8  0x42581afd
%         000000b0:  0x3200001e  0x23000f1d  0x43f82c0d  0x53f83186
%         000000c0:  0x33000004


%Bits pattern
%         ch    measure
%xxxxxxxx xxxxx xxxxxxxxxxxxxxxxxxx
headerDecoding = 196609;%decoding: 0x00030001
headerId       = 8192;  %id:       0x00002000

TRBDecoding    = 131073;%decoding: 0x00020001


% 
% 
% initialEvent     = hex2dec('01');%TC trigger code
% 
% 
% 
leadMeas         = 4;
trailMeas        = 5;
extensionSize    = 3; 
% 
leadMeansActive  = 0;
trailMeansActive = 0;
% channels         = zeros(128,1);

t = clock;

done = 1;
counterFile = 1;

previusA = [];%This is for the remaining events after processing


fid=fopen([pathIn{1} filename{1} ext{1}],'r');
if fid == (-1)
    error(['rdf: Could not open file:' pathIn{1} filename{1} ext{1}]);
end


while done

    %Read out the data
    A= fread(fid,numberOfBitsToRead,'uint32');
    
    
    %Check if the readout is finished
    if(length(A) < numberOfBitsToRead);done = 0;end

    %Concatenate the previous events
    A= [previusA; A];
    
   
%   Calculate the ids for the beguining of each event, in this case size: 0x0000015c
%   size: 0x0000015c  decoding: 0x00030001  id:    0x00002000  seqNr:  0x00000001
%   date: 2013-08-01  time:     13:57:11    runNr: 0x0a73dd37  expId:
    
    eventSizeId = intersect(find(A == headerDecoding)+1,find(A == headerId)) -2;
    
      

    %%%Cat the data and leave the not complete data
    previusA = A(eventSizeId(end):length(A));
    A = A(1:eventSizeId(end)-1);
    %%%Recalculate the eventSizeId
    eventSizeId = eventSizeId(1:end-1);
    numberOfEvents = length(eventSizeId);
    
    %%Verification
    if(sum(A(eventSizeId + 7)))
        disp('Something is wrong with the indexing');
        %keyboard
    end
    
    
    
    %%%Stract the eventTime
    eventDate = A(eventSizeId + 4);
    eventTime = A(eventSizeId + 5);
    
    %%%Delete no useful information to preven missCoincidences.
    %%%This 
    %  size: 0x00000020  decoding: 0x00030001  id:    0x00010002  seqNr:  0x00000000
    %  date: 2013-08-01  time:     13:57:11    runNr: 0x0a73dd37  expId:

    if(counterFile == 1)
        A(1:8) = 0;
    end
    
    
    %%%And this
    %   size: 0x0000015c  decoding: 0x00030001  id:    0x00002000  seqNr:  0x00000001
    %   date: 2013-08-01  time:     13:57:11    runNr: 0x0a73dd37  expId:
    A(eventSizeId +1) = 0;A(eventSizeId +2) = 0;A(eventSizeId +3) = 0;A(eventSizeId +4) = 0;
    A(eventSizeId +5) = 0;A(eventSizeId +6) = 0;A(eventSizeId +7) = 0;
    
    
    %%%Calculate the TRBsizeId
    TRBSizeId = zeros(numberOfEvents,size(TRBIds,2));
    for i=1:size(TRBIds,2)
        TRBSizeId(:,i) = intersect(find(A == TRBDecoding)+1,find(A == TRBIds(i))) - 2;
    
        %%Verification
        if(diff(A(TRBSizeId(:,i) + 1)))
            disp('Something is wrong with the indexing');
           % keyboard
        end
    end
    
    extendedDataNumber = A(eventSizeId(1)+13);%It is assumed that all TRBs have same number of extended data. It should be like this
    
    %%% Data preallocation. Rows are events, colums are the extended
    %%% data information and layers are TRBs
    extendedData = zeros(numberOfEvents,extendedDataNumber,size(TRBIds,2));
      
    for i=1:size(TRBIds,2)
        for j=1:extendedDataNumber
            extendedData(:,j,i) = A(TRBSizeId(:,i)+5+j); 
        end
    end
    
        
    %%%Delete no useful information to preven missCoincidences.
    
    for i=1:size(TRBIds,2)
        %%%This
        %   00000000:              0x00000003  0x00000000  0x00000000
        %   00000010:  0x00000000  
        for j=1:extensionSize+1
            A(TRBSizeId(:,i) + 4 + j) = 0;
        end
        %%%And this
        %   size:        decoding: 0x00020001  id:    0x00000343  trigNr: 0x00000000
% 
            A(TRBSizeId(:,i) + 1) = 0;A(TRBSizeId(:,i) + 2) = 0;A(TRBSizeId(:,i) + 3) = 0;
    end
    
    %%%Create the eventIndex and TRBIndex
    eventIndex = zeros(length(A),1);
    TRBIndex   = zeros(length(A),1);
    
    for i=1:length(eventSizeId)
        eventIndex(eventSizeId(i):(eventSizeId(i) + A(eventSizeId(i))/4)) = i;
        for j=1:size(TRBIds,2)
            TRBIndex(  TRBSizeId(i,j):(TRBSizeId(i,j) + A(TRBSizeId(i,j))/4)) = j;
        end
        %TRBIndex(,1) = 2;
    end
    
    disp(['=== Number of events ' sprintf('%08d' ,numberOfEvents)]);
    %wordsOnEvent   = bitand(uint32(A(idInitialEvent)),uint32(hex2dec('0000ffff')));%Extract the words on each Event
    
    idAllEvents    = bitshift(A,-28);
    if(length(find(idAllEvents == leadMeas)) > 0);leadMeansActive    = 1;disp('=== Leading measure Active.');end
    if(length(find(idAllEvents == trailMeas)) > 0);trailMeansActive    = 1;disp('=== Trailing measure Active.');end
    
    
    
    %%% Extract the information for everithing.
    TDC     = double(bitshift(bitand(uint32(A),uint32(hex2dec('0f000000'))),-24));%Extract the TDC chip 0-3
    channel = double(bitshift(bitand(uint32(A),uint32(hex2dec('00f80000'))),-19));%Extract the channels 0-31
    time    = double(bitand(uint32(A),uint32(hex2dec('0007ffff'))));%Extract the time
    
    %%% Now construct the leding time together with the channel
    idLead = find(idAllEvents == leadMeas);
    leading   = [eventIndex(idLead) TRBIndex(idLead) ((channel(idLead) +1)+(32*(TDC(idLead)))) time(idLead)];
    [lixo,n,lixo] = unique(leading(:,1:3),'rows','first');
    leading = leading(n,:);
    
    
   
    
    %%% Now construct the trailing time together with the channel
    idTrail = find(idAllEvents == trailMeas);
    trailing   = [eventIndex(idTrail) TRBIndex(idTrail) ((channel(idTrail) +1)+(32*(TDC(idTrail)))) time(idTrail)];
    [lixo,n,lixo] = unique(trailing(:,1:3),'rows','first');
    trailing = trailing(n,:);
   
    %%%Loop on the TRBs
    for i=1:size(TRBIds,2)
        %%%Select the desired TRB
        I = find(leading(:,2) == i);
        dataLeadings  = sparse(leading(I,1),leading(I,3),leading(I,4),numberOfEvents,128);
        I = find(trailing(:,2) == i);
        dataTrailings = sparse(trailing(I,1),trailing(I,3),trailing(I,4),numberOfEvents,128);
        
        %% Correct INL
        if INLCorrectionActive
            disp(['Applying corrections for TRB ' num2str(TRBIds(i))]);
            load(INLParameters);
            eval(['INLPars = Pars_' num2str(TRBIds(i)) ';']);
            %Process dataLeadings
            %row here is event and colum is channel
            [evt4INL,ch4INL,timeINL] = find(dataLeadings);
            LIdataLeadings = sub2ind(size(dataLeadings),evt4INL,ch4INL);
            %Calculate the LSB and upper part of the time
            LSB = bitand(timeINL,hex2dec('000000FF'));
            UPB = bitand(timeINL,hex2dec('FFFFFF00'));
            linearInd = sub2ind(size(INLPars),ch4INL,(LSB + 1));
            dataLeadings = sparse(evt4INL,ch4INL,(UPB + LSB + INLPars(linearInd)),size(dataLeadings,1),size(dataLeadings,2)) ;
            
            %Process dataTrailings
            %row here is event and colum is channel
            [evt4INL,ch4INL,timeINL] = find(dataTrailings);
            LIdataTrailings = sub2ind(size(dataTrailings),evt4INL,ch4INL);
            %Calculate the LSB and upper part of the time
            LSB = bitand(timeINL,hex2dec('000000FF'));
            UPB = bitand(timeINL,hex2dec('FFFFFF00'));
            linearInd = sub2ind(size(INLPars),ch4INL,(LSB + 1));
            dataTrailings = sparse(evt4INL,ch4INL,((UPB) + (LSB) + INLPars(linearInd)),size(dataTrailings,1),size(dataTrailings,2)) ;
        end
        
        %% Substract the reference time
        for i_=1:4
            for j_=1:31
                I = find(dataLeadings(:,j_+(i_-1)*32) ~=0);
                if(length(I) > 0);dataLeadings(I,j_+(i_-1)*32) = -(dataLeadings(I,j_+(i_-1)*32) - dataLeadings(I,i_*32));end
                I = find(dataTrailings(:,j_+(i_-1)*32) ~=0);
                if(length(I) > 0);dataTrailings(I,j_+(i_-1)*32) = -(dataTrailings(I,j_+(i_-1)*32) - dataLeadings(I,i_*32));end
            end
        end
        %%%Save information
        save([pathOut{1} filename{1} '_TRB' num2str(TRBAlias(i)) '_part' sprintf('%04d',counterFile)],'dataLeadings','dataTrailings','numberOfEvents','extendedData','eventTime','eventDate','TRBIds');
      end
    l=etime(clock,t);
    disp(['=== Ellapsed Time ' sprintf('%5.1f' ,l) ' seconds'])
    disp(['=== file ', filename{1}, ext{1}, ' with ', num2str(numberOfEvents), ' events ']);
    disp(['=== read in ', pathIn{1} ,' and written in ', pathOut{1}]);
    
    counterFile = counterFile + 1;

end

fclose(fid);

return
