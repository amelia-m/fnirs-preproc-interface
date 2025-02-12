classdef MeasListClass < FileLoadSaveClass
    
    % Properties implementing the MeasList fields from the SNIRF spec
    properties
        sourceIndex
        detectorIndex
        wavelengthIndex
        dataType
        dataTypeLabel
        dataTypeIndex   % Used for condition when dataType=99999 ("Processed") and dataTypeLabel='HRF...'
        sourcePower
        detectorGain
        moduleIndex
    end
    
       
    methods

        function obj = MeasListClass(varargin)
            %
            %  Syntax:
            %     obj = MeasListClass()
            %     obj = MeasListClass(ml)
            %     obj = MeasListClass(sourceIndex, detectorIndex, wavelengthIndex)
            %     obj = MeasListClass(sourceIndex, detectorIndex, dataType)
            %     obj = MeasListClass(sourceIndex, detectorIndex, dataType, dataTypeLabel)
            %     obj = MeasListClass(sourceIndex, detectorIndex, dataType, dataTypeLabel, condition)
            %     
            %  Inputs:
            %     ml             - When there's one argument, ml is the measurent list, which 
            %                      can be either a nirs style matrix or a MeasListClass object.
            %     sourceIndex    - When there are more than 2 arguments, ...
            %     detectorIndex  - When there are more than 2 arguments, ...
            %     dataType       - When there are more than 2 arguments, ...
            %     dataTypeLabel  - When there are more than 2 arguments, ...
            %     dataTypeIndex  - When there are more than 2 arguments, ...
            %
            %  Example:
            %
            
            % Fields which are part of the SNIRF spec which are loaded and saved 
            % from/to SNIRF files
            obj.sourceIndex      = 0;
            obj.detectorIndex    = 0;
            obj.wavelengthIndex  = 0;
            obj.dataType         = 0;
            obj.dataTypeLabel    = '';
            obj.dataTypeIndex    = 0;
            obj.sourcePower      = 0;
            obj.detectorGain     = 0;
            obj.moduleIndex      = 0;
            
            dataTypeValues = DataTypeValues();

            if nargin==1 && isa(varargin{1}, 'MeasListClass')
                obj                  = varargin{1}.copy();                    % shallow copy ok because MeasListClass has no handle properties 
            elseif nargin==1 
                obj.sourceIndex      = varargin{1}(:,1);
                obj.detectorIndex    = varargin{1}(:,2);
                obj.wavelengthIndex  = varargin{1}(:,4);
                obj.dataType         = dataTypeValues.Raw.CW.Amplitude;
            elseif nargin==3
                obj.sourceIndex      = varargin{1};
                obj.detectorIndex    = varargin{2};
                obj.dataType         = varargin{3};
            elseif nargin==4
                obj.sourceIndex      = varargin{1};
                obj.detectorIndex    = varargin{2};
                obj.dataType         = varargin{3};
                obj.dataTypeLabel    = varargin{4};
            elseif nargin==5
                obj.sourceIndex      = varargin{1};
                obj.detectorIndex    = varargin{2};
                obj.dataType         = varargin{3};
                obj.dataTypeLabel    = varargin{4};
                obj.dataTypeIndex    = varargin{5};
            end
            
            % Set base class properties not part of the SNIRF format
            obj.SetFileFormat('hdf5');

        end
        
        
        % -------------------------------------------------------
        function err = LoadHdf5(obj, fileobj, location, fieldnames)
            err = 0;
            
            % Arg 1
            if ~exist('fileobj','var') || (ischar(fileobj) && ~exist(fileobj,'file'))
                fileobj = '';
            end

            % Arg 2
            if ~exist('location', 'var') || isempty(location)
                location = '/nirs/data1/measurementList1';
            elseif location(1)~='/'
                location = ['/',location];
            end
            
            % Error checking            
            if ~isempty(fileobj) && ischar(fileobj)
                obj.SetFilename(fileobj);
            elseif isempty(fileobj)
                fileobj = obj.GetFilename();
            end
            if isempty(fileobj)
               err = -1;
               return;
            end

            try
                % Open group
                [gid, fid] = HDF5_GroupOpen(fileobj, location);
                % Load datasets
                % tic
                for thisField = fieldnames
                    obj.(thisField) = HDF5_DatasetLoad(gid, thisField);
                end
                for ifield = 1:H5G.get_info(gid).nlinks
                    
                end
                % toc
                % tic
                % obj.sourceIndex     = HDF5_DatasetLoad(gid, 'sourceIndex');
                % obj.detectorIndex   = HDF5_DatasetLoad(gid, 'detectorIndex');
                % obj.wavelengthIndex = HDF5_DatasetLoad(gid, 'wavelengthIndex');
                % obj.dataType        = HDF5_DatasetLoad(gid, 'dataType');
                % obj.dataTypeIndex   = HDF5_DatasetLoad(gid, 'dataTypeIndex');
                % % obj.dataTypeLabel   = HDF5_DatasetLoad(gid, 'dataTypeLabel', obj.dataTypeLabel);
                % obj.sourcePower     = HDF5_DatasetLoad(gid, 'sourcePower');
                % obj.detectorGain     = HDF5_DatasetLoad(gid, 'detectorGain');
                % obj.moduleIndex     = HDF5_DatasetLoad(gid, 'moduleIndex');
                % toc
                % disp(1)
                HDF5_GroupClose(fileobj, gid, fid);
            catch
                err = -1;
                return
            end
            
            if obj.IsEmpty()
                err = -1;
            end
            if obj.sourceIndex<1
                err = -1;
            end
            if obj.detectorIndex<1
                err = -1;
            end

            obj.SetError(err);
        end

        
        % -------------------------------------------------------
        function err = SaveHdf5(obj, fileobj, location)
            err = 0;
            
            % Arg 1
            if ~exist('fileobj', 'var') || isempty(fileobj)
                error('Unable to save file. No file name given.')
            end
            
            % Arg 2
            if ~exist('location', 'var') || isempty(location)
                location = '/nirs/data1/measurementList1';
            elseif location(1)~='/'
                location = ['/',location];
            end

            % Convert file object to HDF5 file descriptor
            fid = HDF5_GetFileDescriptor(fileobj);
            if fid < 0
                err = -1;
                return;
            end
            
            hdf5write_safe(fid, [location, '/sourceIndex'], uint64(obj.sourceIndex));
            hdf5write_safe(fid, [location, '/detectorIndex'], uint64(obj.detectorIndex));
            hdf5write_safe(fid, [location, '/wavelengthIndex'], uint64(obj.wavelengthIndex));
            hdf5write_safe(fid, [location, '/dataType'], uint64(obj.dataType));
            hdf5write_safe(fid, [location, '/dataTypeLabel'], obj.dataTypeLabel);
            hdf5write_safe(fid, [location, '/dataTypeIndex'], uint64(obj.dataTypeIndex));
            hdf5write_safe(fid, [location, '/sourcePower'], obj.sourcePower);
            hdf5write_safe(fid, [location, '/detectorGain'], obj.detectorGain);
            hdf5write_safe(fid, [location, '/moduleIndex'], uint64(obj.moduleIndex));
        end

                
        % ---------------------------------------------------------
        function idx = GetSourceIndex(obj)
            idx = obj.sourceIndex;
        end
        
        
        % ---------------------------------------------------------
        function idx = GetDetectorIndex(obj)
            idx = obj.detectorIndex;
        end
        
        
        % ---------------------------------------------------------
        function idx = GetWavelengthIndex(obj)
            idx = obj.wavelengthIndex;
        end
        
        
        % ---------------------------------------------------------
        function SetWavelengthIndex(obj, val)
            obj.wavelengthIndex = val;
        end
        
        
        % ---------------------------------------------------------
        function SetDataType(obj, dataType, dataTypeLabel)
            obj.dataType = dataType;
            obj.dataTypeLabel = dataTypeLabel;
        end
        
        
        % ---------------------------------------------------------
        function SetDataTypeLabel(obj, dataTypeLabel)
            obj.dataTypeLabel = dataTypeLabel;
        end
        
        
        % ---------------------------------------------------------
        function [dataType, dataTypeLabel] = GetDataType(obj)
            dataType = obj.dataType;
            dataTypeLabel = obj.dataTypeLabel;
        end
        
        
        % ---------------------------------------------------------
        function dataTypeLabel = GetDataTypeLabel(obj)
            dataTypeLabel = obj.dataTypeLabel;
        end
        
        
        % ---------------------------------------------------------
        function SetCondition(obj, val)
            obj.dataTypeIndex = val;
        end
        
        
        % ---------------------------------------------------------
        function val = GetCondition(obj)
            val = obj.dataTypeIndex;
        end
        
        
        % -------------------------------------------------------
        function b = IsEmpty(obj)
            b = false;
            if isempty(obj.sourceIndex) && isempty(obj.detectorIndex)
                b = true;
                return
            end
        end

        
        % -------------------------------------------------------
        function B = eq(obj, obj2)
            B = false;       
            if obj.sourceIndex~=obj2.sourceIndex
                return;
            end
            if obj.detectorIndex~=obj2.detectorIndex
                return;
            end
            if obj.wavelengthIndex~=obj2.wavelengthIndex
                return;
            end
            if obj.dataType~=obj2.dataType
                return;
            end
            if ~strcmp(obj.dataTypeLabel, obj2.dataTypeLabel)
                return;
            end
            if obj.dataTypeIndex~=obj2.dataTypeIndex
                return;
            end
            if obj.sourcePower~=obj2.sourcePower
                return;
            end
            if obj.detectorGain~=obj2.detectorGain
                return;
            end
            if obj.moduleIndex~=obj2.moduleIndex
                return;
            end
            B = true;
        end
        
        
        % ----------------------------------------------------------------------------------        
        function nbytes = MemoryRequired(obj)
            nbytes = 0;
            fields = properties(obj);
            for ii=1:length(fields)
                nbytes = nbytes + eval(sprintf('sizeof(obj.%s)', fields{ii}));
            end
        end        
        
    end
    
end

