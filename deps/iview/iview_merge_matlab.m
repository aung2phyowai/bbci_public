function iview_merge_matlab( bv_file_name, iview_file_name, varargin )
%
% IVIEW_MERGE_MATLAB - merge two EEG data files
% 


%TODO current assumptions
% frequency == time unit (time values are used as indices)
% second marker is merge marker

props= {'rec_start_marker'   100            '!INT[1]'
    };
opts = opt_proplistToStruct(varargin{1:end});
params = opt_setDefaults(opts, props, 1);
display(['Merging ' bv_file_name ' and ' iview_file_name '...'])

[bv_CNT, bv_MRK, bv_HDR] = file_readBV(bv_file_name);
display(['Raw EEG data size: ' num2str(bv_CNT.T)])

[iview_CNT, ~, iview_HDR] = file_readBV(iview_file_name);
display(['Raw iView data size: ' num2str(iview_CNT.T)])

if bv_CNT.fs ~= 1000 || iview_CNT.fs ~= 1000
    error('currently supporting only 1kHz sampling')
end

bv_number_of_channels = size(bv_CNT.x, 2);
iview_number_of_channels = size(iview_CNT.x, 2);
additional_channels = (bv_number_of_channels+1):(bv_number_of_channels+iview_number_of_channels); 

sync_marker_idx = find(bv_MRK.event.desc == params.rec_start_marker, 1);
offset = bv_MRK.time(sync_marker_idx);

bv_CNT.x(1 + offset:iview_CNT.T + offset, additional_channels) = iview_CNT.x;
bv_CNT.clab(additional_channels) = iview_CNT.clab;
bv_HDR.unitOfClab(additional_channels) = iview_HDR.unitOfClab;

file_writeBV([bv_file_name 'merged'], bv_CNT, bv_MRK, 'Unit', bv_HDR.unitOfClab);

display('Done!');

end

