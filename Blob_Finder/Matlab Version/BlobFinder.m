function [Blobs, Assigned_Blob] = BlobFinder(BW_Image, Pixel_Threshold)
Assigned_Blob = zeros(size(BW_Image),'uint64');
Blobs = struct();
BlobCount = 0;
PixelCount = zeros(numel(BW_Image),1);
Ymin = PixelCount;
Ymax = PixelCount;
Xmin = PixelCount;
Xmax = PixelCount;
Xsum = PixelCount;
Ysum = PixelCount;
% Determmine 1-D Blob Locations (connect blobs with adjacent columns)

for j = 1:size(BW_Image,2)
    for i = 1:size(BW_Image,1)
        if BW_Image(i,j)
            if i == 1 || ~BW_Image(i-1,j)
                BlobCount = BlobCount + 1;
                Ymin(BlobCount) = i;
                Xmin(BlobCount) = j;
                Xmax(BlobCount) = j;
            end
            PixelCount(BlobCount) = PixelCount(BlobCount) + 1;
            Ymax(BlobCount) = i;
            Xsum(BlobCount) = Xsum(BlobCount) + j;
            Ysum(BlobCount) = Ysum(BlobCount) + i;
        end
    end
end

PixelCount = PixelCount(1:BlobCount);
Ymin = Ymin(1:BlobCount);
Ymax = Ymax(1:BlobCount);
Xmin = Xmin(1:BlobCount);
Xmax = Xmax(1:BlobCount);
Xsum = Xsum(1:BlobCount);
Ysum = Ysum(1:BlobCount);

for iBlob = 1:BlobCount
    Blobs(iBlob).PixelCount = PixelCount(iBlob);
    Blobs(iBlob).Ymin = Ymin(iBlob);
    Blobs(iBlob).Ymax = Ymax(iBlob);
    Blobs(iBlob).Xmin = Xmin(iBlob);
    Blobs(iBlob).Xmax = Xmax(iBlob);
    Blobs(iBlob).Local_Ymin = Ymin(iBlob);
    Blobs(iBlob).Local_Ymax = Ymax(iBlob);
    Blobs(iBlob).Local_Xmin = Xmin(iBlob);
    Blobs(iBlob).Local_Xmax = Xmax(iBlob);
    Blobs(iBlob).Xsum = Xsum(iBlob);
    Blobs(iBlob).Ysum = Ysum(iBlob);
    Blobs(iBlob).BlobNumber = iBlob;
end

% Now merge them together (column by column) 
BlobNumbers = cell2mat({Blobs.BlobNumber}');
for iBlob = 1:numel(BlobNumbers)
    RowStartPt = Blobs(iBlob).Local_Ymin;
    RowEndPt = Blobs(iBlob).Local_Ymax;
    Col = Blobs(iBlob).Xmin;
    Assigned_Blob(RowStartPt:RowEndPt,Col) = Blobs(iBlob).BlobNumber;
end

if BlobCount > 1
    IterationIndex = [2:size(BW_Image,2), (size(BW_Image,2)-1):-1:2];
    for iCol = IterationIndex %2:size(BW_Image,2)
        LowerBlobLocations = eq(Xmin,(iCol-1));
        UpperBlobLocations = eq(Xmin,(iCol));
        LowerRowBlobs = Blobs(LowerBlobLocations);
        UpperRowBlobs = Blobs(UpperBlobLocations);
        if numel(LowerRowBlobs) == 0 || numel(UpperRowBlobs) == 0
            continue
        end
        BlobMatches = false(numel(UpperRowBlobs),numel(LowerRowBlobs));
        for iLower = 1:numel(LowerRowBlobs)
            yp1 = LowerRowBlobs(iLower).Local_Ymin;
            yp2 = LowerRowBlobs(iLower).Local_Ymax;
            for iUpper = 1:numel(UpperRowBlobs)
                y1 = UpperRowBlobs(iUpper).Local_Ymin;
                y2 = UpperRowBlobs(iUpper).Local_Ymax;
                BlobMatches(iUpper,iLower) = Overlap(y1,y2,yp1,yp2); %% Determine Blob Matches
                if  BlobMatches(iUpper,iLower)
                    UpperBlob = UpperRowBlobs(iUpper);
                    LowerBlob = LowerRowBlobs(iLower);
                    MinBlobNumber = min(LowerBlob.BlobNumber, UpperBlob.BlobNumber);
%                     if LowerBlob.BlobNumber > UpperBlob.BlobNumber
%                         Assigned_Blob(eq(Assigned_Blob,LowerBlob.BlobNumber)) = MinBlobNumber;
%                         for iBlob = 1:BlobCount
%                             if Blobs(iBlob).BlobNumber == LowerBlob.BlobNumber 
%                                 Blobs(iBlob).BlobNumber = MinBlobNumber;
%                             end
%                         end
%                     elseif UpperBlob.BlobNumber > LowerBlob.BlobNumber
%                         Assigned_Blob(eq(Assigned_Blob,UpperBlob.BlobNumber)) = MinBlobNumber;
%                     end
                    UpperBlob.BlobNumber = MinBlobNumber;
                    LowerBlob.BlobNumber = MinBlobNumber;
                    UpperRowBlobs(iUpper) = UpperBlob;
                    LowerRowBlobs(iLower) = LowerBlob;
                end
            end 
        end
        Blobs(LowerBlobLocations) = LowerRowBlobs;
        Blobs(UpperBlobLocations) = UpperRowBlobs;
    end
end

% Now merge them together (column by column) 
BlobNumbers = cell2mat({Blobs.BlobNumber}');
for iBlob = 1:numel(BlobNumbers)
    RowStartPt = Blobs(iBlob).Local_Ymin;
    RowEndPt = Blobs(iBlob).Local_Ymax;
    Col = Blobs(iBlob).Xmin;
    Assigned_Blob(RowStartPt:RowEndPt,Col) = Blobs(iBlob).BlobNumber;
end

[SortedBlobNumbers, BlobSortOrder] = sort(cell2mat({Blobs.BlobNumber}));
Blobs = Blobs(BlobSortOrder);
Blobs = rmfield(Blobs,{'Local_Ymin';'Local_Ymax';'Local_Xmin';'Local_Xmax'});
for iBlob = 1:numel(Blobs)
    if iBlob ~= 1 && isequal(SortedBlobNumbers(iBlob),SortedBlobNumbers(iBlob-1))
        MergedBlob = MergeBlobs(Blobs(iBlob), Blobs(iBlob-1));
        Fields = fieldnames(MergedBlob);
        for iField = 1:numel(Fields)
            Blobs(iBlob).(Fields{iField}) = MergedBlob.(Fields{iField});
        end
    end
end

[~,Blobs_to_Keep] = unique(SortedBlobNumbers,'last');
Blobs = Blobs(Blobs_to_Keep);
if exist('Pixel_Threshold','var')
    PixelCount = cell2mat({Blobs.PixelCount});
    Blobs = Blobs(PixelCount >= Pixel_Threshold);
end
    
for iBlob = 1:numel(Blobs)
    Blobs(iBlob).X_Centroid = Blobs(iBlob).Xsum/Blobs(iBlob).PixelCount;
    Blobs(iBlob).Y_Centroid = Blobs(iBlob).Ysum/Blobs(iBlob).PixelCount;
end

end

function Value = Overlap(x1,x2,xp1,xp2)
    %   Conditions:     y2 >= y1 && yp2 >= yp1
    if (xp1 > x2 || x1 > xp2)
        Value = false;
    else
        Value = true;
    end
end

function MergedBlob = MergeBlobs(LowerBlob,UpperBlob) 
    MergedBlob.PixelCount = LowerBlob.PixelCount + UpperBlob.PixelCount;
    MergedBlob.Xmax = max(LowerBlob.Xmax,UpperBlob.Xmax);
    MergedBlob.Xmin = min(LowerBlob.Xmin,UpperBlob.Xmin);
    MergedBlob.Xsum = LowerBlob.Xsum + UpperBlob.Xsum;
    MergedBlob.Ymax = max(LowerBlob.Ymax,UpperBlob.Ymax);
    MergedBlob.Ymin = min(LowerBlob.Ymin,UpperBlob.Ymin);
    MergedBlob.Ysum = LowerBlob.Ysum + UpperBlob.Ysum;
end


