function [ output_args ] = vco_segmentation( cnt, ival, varargin )
%VCO_SEGMENTATION Summary of this function goes here
%   Detailed explanation goes here
props= {'LoadFromMat'   true   'BOOL'};


opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(ival, 'DOUBLE[- 2]');

end

