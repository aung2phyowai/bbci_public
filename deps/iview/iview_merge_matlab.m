function iview_merge_matlab( bv_file_name, iview_file_name )
%
% IVIEW_MERGE_MATLAB - merge two EEG data files
% 

display(['Merging ' bv_file_name ' and ' iview_file_name '...'])

[bv_CNT, bv_MRK, bv_HDR] = file_readBV(bv_file_name);
display(['Raw EEG data size: ' num2str(bv_CNT.T)])

[iview_CNT, iview_MRK, iview_HDR] = file_readBV(iview_file_name);
display(['Raw iView data size: ' num2str(iview_CNT.T)])

bv_number_of_channels = size(bv_CNT.x, 2);
iview_number_of_channels = size(iview_CNT.x, 2);
additional_channels = (bv_number_of_channels+1):(bv_number_of_channels+iview_number_of_channels); 

offset = bv_MRK.time(2);

bv_CNT.x(1 + offset:iview_CNT.T + offset, additional_channels) = iview_CNT.x;
bv_CNT.clab(additional_channels) = iview_CNT.clab;
bv_HDR.unitOfClab(additional_channels) = iview_HDR.unitOfClab;

file_writeBV([bv_file_name 'merged'], bv_CNT, bv_MRK, 'Unit', bv_HDR.unitOfClab);

display('Done!');

end

