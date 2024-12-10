"""
    Collection of functions for analysis of BRW (HDF5) files generated with the BrainWave program from the company 3Brain.
    Laboratory 19 of the CINVESTAV in charge of Dr. Rafael Gutierrez Aguilar.
    Work developed mainly by Isabel Romero-Maldonado (2020 - )
    isabelrm.biofisica@gmail.com
    https://github.com/LBitn
    https://github.com/LBitn/Hippocampus-HDMEA-CSDA.git
"""
# ------------------------------------------------------------------------------------------------------------ #
__precompile__()
# ------------------------------------------------------------------------------------------------------------ #
module AllSTEPs

# ----------------------------------------------------------------------------------------- #
# Import necessary native modules
# ----------------------------------------------------------------------------------------- #
using Dates
using DSP
using HDF5
using InteractiveUtils
using JLD2
using Measures
using Plots
using Primes
using StatsBase
using Suppressor
# ----------------------------------------------------------------------------------------- #

# ----------------------------------------------------------------------------------------- #
# Functions to be exported
# ----------------------------------------------------------------------------------------- #
    # STEP00
export FindDirsFiles
export GetVarsHDF5
export GetChunkSize
export ChunkSizeSpace
export OneSegment
export Digital2Analogue
export SupInfThr
export UniqueCount
export STDΔV
export ms2frs
    # STEP01
export SearchDir
export LoadDict
export BarPlot
export SupThr
export ReduceArrayDistance
export Neighbours
export ReconstructChannels
export PatchEmpties
export Zplot
    # Jorgio functions
export Channel_Spectrogram
    # aux
export convgauss
export RemoveInfs
# ----------------------------------------------------------------------------------------- #

# ----------------------------------------------------------------------------------------- #
# Function definitions
# ----------------------------------------------------------------------------------------- #
function FindDirsFiles( start::AbstractString, word::AbstractString )
    # Create an empty array to store the matching paths (both directories and files)
    matching_paths = Vector{ String }( );
    # Define a nested function to recursively search through directories
    function SearchDir( dir::AbstractString )
        # Get the list of entries (files and folders) in the current directory
        entries = readdir( dir );
        # Loop through each entry found in the directory
        for entry in entries
            # Join the directory path with the entry name to form the full path
            entry_path = joinpath( dir, entry );
            # If the entry is a directory and not a hidden folder (starting with ".")
            if isdir( entry_path ) && !startswith( entry, "." )
                # If the directory name contains the target word, add it to matching_paths
                if contains( entry, word )
                    push!( matching_paths, entry_path );
                end
                # Recursively call SearchDir to search within this subdirectory
                SearchDir( entry_path );
            # If the entry is a file and its name contains the target word
            elseif contains( entry, word )
                # Add the file path to matching_paths
                push!( matching_paths, entry_path );
            end
        end
    end
    # Start the recursive search from the root/start directory
    SearchDir( start );
    # Separate matching directories from matching_paths
    D = matching_paths[ isdir.( matching_paths ) ];
    # Separate matching files from matching_paths
    F = matching_paths[ isfile.( matching_paths ) ];
    # Return the matching directories and files
    return D, F
end

"""
    GetGroupsHDF5( filename::HDF5.File, g::AbstractString ) → Groups::Vector{ String }
        Extracts the names of all sub-groups contained within a specified group in an open
        HDF5 file.

        **Purpose**
        This function retrieves all sub-groups (nested groups) within a specified group in an
        HDF5 file. It helps in identifying the hierarchical structure of the HDF5 file by
        listing all groups that are directly contained within a given group. This can be
        useful for traversing and analyzing the group structure of complex HDF5 files.

        **Inputs**
        - `filename`: An open HDF5 file object that contains the group from which sub-groups are
        to be extracted.
        - `g`: A string representing the path to the specific group within the HDF5 file for
        which sub-groups are being queried.

        **Outputs**
        - `Groups`: A vector of strings where each string represents the path to a sub-group
        contained within the specified group. Each path is a combination of the parent group
        path and the sub-group name.

        **Requirements**
        - **Native Modules**: `HDF5`
"""
function GetGroupsHDF5( filename::HDF5.File, g::String )
    # Retrieve and construct full paths for each group within the specified group `g`
    return [ string( g, "/", key ) for key in keys( filename[ g ] ) ];
end

"""
    GetAttrHDF5( filename::HDF5.File, g::AbstractString ) → Attributes::Vector{ String }
        Extracts the attributes contained within a specific group in an open HDF5 file.

        **Purpose**
        This function retrieves all attribute names associated with a specified group in an
        HDF5 file. Attributes provide metadata about the data stored in the HDF5 file, and
        this function allows users to obtain and list these attributes for a given group.
        This can be useful for inspecting metadata or for preprocessing data before further
        analysis.

        **Inputs**
        - `filename`: An open HDF5 file object that contains the group from which attributes are
        to be extracted.
        - `g`: A string representing the path to the specific group within the HDF5 file for
        which attributes are being queried.

        **Outputs**
        - `Attributes`: A vector of strings representing the names of all attributes
        associated with the specified group. Each attribute name is provided in a format that
        includes the group path and the attribute key.

        **Requirements**
        - **Native Modules**: `HDF5`
"""
function GetAttrHDF5( filename::HDF5.File, g::String )
    # Retrieve and construct full paths for each attribute within the specified group `g`
    return [ string( g, "/", key ) for key in keys( attributes( filename[ g ] ) ) ];
end

"""
    HDF5Content( filename::HDF5.File ) ⤵
        → Groups::Vector{ String }, Attributes::Vector{ String }
        Extracts all groups and attributes contained in an open HDF5 file.

        **Purpose**
        This function explores the hierarchical structure of an HDF5 file to retrieve and
        list all groups and attributes. It provides a comprehensive view of the HDF5 file's
        structure, including nested groups and associated metadata. This function helps users
        understand the data organization and metadata present in the file, facilitating
        easier navigation and analysis.

        **Inputs**
        - `filename`: An open HDF5 file object that is being examined. This file contains the
        groups and attributes from which information will be extracted.

        **Outputs**
        - `Groups`: A vector of strings representing the names of all unique groups found
        within the HDF5 file. The groups are sorted in ascending order to provide a clear
        hierarchy of the file's structure.
        - `Attributes`: A vector of strings representing the names of all unique attributes
        associated with the groups in the HDF5 file. Attributes are sorted in reverse order
        to assist with detailed metadata review.

        **Requirements**
        - **Custom Functions**: `GetGroupsHDF5`, `GetAttrHDF5`
        - **Native Modules**: `HDF5`
"""
function HDF5Content( filename::HDF5.File )
    # `Groups` stores the initial groups (keys) at the root of the HDF5 file.
    Groups = keys( filename );
    # `AllGroups` will store all groups encountered during the traversal of the HDF5 file.
    AllGroups = Set{String}();
    # `AllAttributes` will store all attributes found at the root of the HDF5 file.
    AllAttributes = Set( keys( attributes( filename ) ) );
    # Loop until all groups have been explored.
    while !isempty( Groups )
        # `NewGroups` will temporarily store new groups discovered at the current level.
        NewGroups = Set{String}();
        # Iterate through the groups in the current level.
        for g in Groups
            # If the current object `g` is a dataset, it gets added directly to `AllGroups`.
            if isa( filename[ g ], HDF5.Dataset )
                push!( AllGroups, g );
            else
                # If the object is not a dataset (another group), use the helper function
                # `GetGroupsHDF5` to find more sub-groups within this group.
                union!( NewGroups, GetGroupsHDF5( filename, g ) );
                # Similarly, use `GetAttrHDF5` to find any attributes within this group.
                union!( AllAttributes, GetAttrHDF5( filename, g ) );
            end
        end
        # Set `Groups` to the newly sub-groups to further explore them in the next loop.
        Groups = collect( NewGroups );
        # Add all the newly found groups to `AllGroups`.
        union!( AllGroups, Groups )
    end
    # After collecting all groups, sort them in ascending order and remove duplicates.
    Groups = sort( unique( collect( AllGroups ) ) );
    # For attributes, sort them in reverse order and remove duplicates as well.
    Attributes = reverse( sort( unique( collect( AllAttributes ) ) ) );
    # Return the sorted lists of groups and attributes.
    return Groups, Attributes
end

"""
    ExtractRawDataset( filename::HDF5.File, GroupsHDF5::Vector{ String } ) ⤵
        → ΔΣ::String, nΔΣ::Vector{ String }

        Identifies and extracts the largest dataset from an open HDF5 file and returns it
        along with the remaining datasets.

        **Purpose**
        This function detects the largest dataset within an HDF5 file based on its size. It
        marks this dataset (ΔΣ) to avoid loading or processing it in subsequent steps due to
        its large size. The function returns the path to this largest dataset and a list of
        all other datasets.

        **Inputs**
        - `filename`: An open HDF5 file object from which datasets and their sizes are examined.
        - `GroupsHDF5`: A vector containing the paths to all groups and datasets found in the
        HDF5 file during traversal.

        **Outputs**
        - `ΔΣ`: The path to the largest dataset within the HDF5 file.
        - `nΔΣ`: A vector of paths to all other datasets that are not the largest one.
        Datasets with zero size are excluded from this list.

        **Requirements**
        - **Native Modules**: `HDF5`
"""
function ExtractRawDataset( filename::HDF5.File, GroupsHDF5::Vector{String} )
# `Types` will store the data types of each group (as strings)
Types = Vector{ String }( undef, length( GroupsHDF5 ) );
# Loop through each group to identify its type and store it in the `Types` array.
for g = 1:length( GroupsHDF5 )
    # For each group, determine its type using `typeof()` and convert it to a string.
    Types[g] = string( typeof( filename[ GroupsHDF5[ g ] ] ) );
end
# Filter `GroupsHDF5` to only keep the ones that are HDF5 datasets.
AllDataSets = GroupsHDF5[ Types .== "HDF5.Dataset" ];
# Create an auxiliary array `aux` that will store the sizes of each dataset.
aux = zeros( Int, length( AllDataSets ) );
# Loop through all datasets and compute their lengths (or size in memory).
for ds = 1:length( AllDataSets )
    aux[ ds ] = length( filename[ AllDataSets[ ds ] ] );
end
# Identify the dataset with the maximum size.
ΔΣ = AllDataSets[ aux .== maximum( aux ) ][ 1 ];
# `nΔΣ` will store all other datasets that are not the largest one.
nΔΣ = AllDataSets[ aux .!= maximum( aux ) ];
# Filter the auxiliary array to exclude zero-length datasets.
aux = aux[ aux .!= maximum( aux ) ];
# Filter `nΔΣ` to only keep non-zero-sized datasets.
nΔΣ = nΔΣ[ aux .!= 0 ];
# Return the largest dataset `ΔΣ` and the remaining datasets `nΔΣ`.
return ΔΣ, nΔΣ
end

"""
    ExtractValues( file::HDF5.File, AllAttributes::Vector{ String }, nΔΣ::Vector{ String } ) ⤵
        → D::Dict

        Extracts values from an HDF5 file for the specified datasets and attributes.

        **Purpose**
        This function extracts data from an HDF5 file, excluding the dataset with the largest
        size. It gathers values from the datasets in `nΔΣ` (excluding the largest one) and
        attributes listed in `AllAttributes`.
        - **Datasets**: For datasets, it attempts to read the data and convert it to
        `Float64`. If this fails, it reads the data in its original format. It also handles
        single-element arrays by extracting the single value and tries to convert the data to
        `Int64` if possible.
        - **Attributes**: For attributes, it reads the attribute values from the HDF5 file or
        its groups, depending on the path provided, and stores them in the dictionary.

        **Inputs**
        - `file`: An open HDF5 file object from which data is read.
        - `AllAttributes`: A vector of attribute paths to be extracted.
        - `nΔΣ`: A vector of dataset paths to be considered, excluding the largest dataset.

        **Outputs**
        - `D`: A dictionary where keys are dataset or attribute paths and values are the
        extracted data. Datasets are stored with their values converted to `Float64` or
        `Int64`, while attributes are stored as they are read.

        **Requirements**
        - **Native Modules**: `HDF5`
"""
function ExtractValues( file::HDF5.File, AllAttributes::Vector{String}, nΔΣ::Vector{String} )
    # Initialize an empty dictionary `D` to store the extracted values.
    D = Dict{ String, Any }( );
    # Loop through each group in `nΔΣ` (which excludes the largest dataset).
    for g in nΔΣ
        try
            # Attempt to read the group values and convert them to `Float64`.
            D[ g ] = Float64.( read( file[ g ] ) );
        catch e
            # If there is an error, just read the group without converting it to `Float64`.
            D[ g ] = read( file[ g ] );
        end
    end
    # Loop through the keys in the dictionary `D`.
    for g in keys( D )
        # If the value in `D` for a key has only one element, extract that single element.
        if length( D[ g ] ) == 1
            D[ g ] = D[ g ][ 1 ];
        end
        try
            # Try to convert the value in `D` to an `Int64`.
            D[ g ] = Int64( D[ g ] );
        catch e
            # Do nothing if the conversion to `Int64` fails.
        end
    end
    # Loop through each attribute path in `AllAttributes`.
    for g in AllAttributes
        # `aux00` gets the base name (file or attribute name) from the full path `g`.
        aux00 = basename( g );
        # `aux01` gets the directory name from the full path `g`.
        aux01 = dirname( g );
        # If `aux01` (the directory path) is empty, it means the attribute is at the root level.
        if isempty( aux01 )
            # Read the attribute from the HDF5 file root level and store it in `D`.
            D[ g ] = read_attribute( file, aux00 );
        else
            # Otherwise, read the attribute from the specified group in the HDF5 file.
            D[ g ] = read_attribute( file[ aux01 ], aux00 );
        end
    end
    # Return the dictionary `D` containing the extracted values.
    return D
end

"""
    Abs2RelPath( D::Dict ) → ND::Dict
        Transforms the key entries from dictionary `D` from absolute paths to relative paths.

        **Purpose**
        This function converts the keys of a dictionary from absolute paths to relative
        paths. This normalization makes dictionary keys more manageable when absolute paths
        are not needed.

        **Inputs**
        - `D`: A dictionary where the keys are absolute paths and the values are associated
        data.

        **Outputs**
        - `ND`: A dictionary where the keys are transformed into relative paths (using only
        the base names of the original absolute paths) while retaining the same values.

        **Requirements**
        - **None**: The function utilizes basic Julia operations and does not rely on any
        external packages.
"""
function Abs2RelPath( D::Dict )
    # Initialize an empty dictionary to store the new key-value pairs with relative paths.
    ND = Dict{ String, Any }( );
    # Extract all keys from the original dictionary.
    K = keys( D );
    # Iterate over each key in the original dictionary.
    for k in K
        # Convert the absolute path key to a relative path (using only the base name).
        # Assign the same value from the original dictionary to the new key.
        ND[ basename( k ) ] = D[ k ];
    end
    # Return the new dictionary with relative path keys.
    return ND
end

"""
    ExpDate2Str( Variables::Dict ) → Variables::Dict
        If an "ExperimentDateTime" key exists in the "Variables" dictionary, it is converted
        to a human-readable format.

        **Purpose**
        This function checks if the "ExperimentDateTime" key exists in the provided
        dictionary. If it does, the function converts its value from a format that includes
        non-numeric characters to a human-readable date-time string. This standardizes
        date-time formats for easier interpretation.

        **Inputs**
        - `Variables`: A dictionary that may contain an "ExperimentDateTime" key with a
        date-time string that needs conversion.

        **Outputs**
        - `Variables`: The same dictionary with the "ExperimentDateTime" key updated to a
        human-readable date-time string if the key was present.

        **Requirements**
        - **Native Modules**: `Dates`
"""
function ExpDate2Str( Variables::Dict )
    # Check if the "ExperimentDateTime" key exists in the dictionary.
    if "ExperimentDateTime" in keys( Variables )
        # Retrieve the value associated with the "ExperimentDateTime" key.
        ExperimentDateTime = Variables[ "ExperimentDateTime" ];
        # Split the date-time string by colons to process its components.
        Dt = split( ExperimentDateTime, ":" );
        # Modify the last component of the date-time string by rounding and removing
        # non-numeric characters.
        Dt[ end ] = string(
            round( Int, parse( Float64, replace( Dt[end], r"[A-Z]" => "" ) ) ) );
        # Initialize an empty string to build the new date-time format.
        newDt = String( "" );
        # Concatenate the modified components back together with colons.
        for i in Dt
            newDt *= ":" * i;
        end
        # Remove the leading colon from the newly built date-time string.
        newDt = newDt[ 2:end ];
        # Convert the new date-time string to a `DateTime` object using the `Dates` package.
        ExperimentDateTime = Dates.DateTime( newDt );
        # Update the dictionary with the new human-readable date-time string.
        Variables[ "ExperimentDateTime" ] = string( ExperimentDateTime );
    end
    # Return the updated dictionary.
    return Variables
end

"""
    ExpSett2Dict( Variables::Dict ) → Variables::Dict
        If an "ExperimentSettings" key exists in the "Variables" dictionary, it extracts the
        values and places them at the same level as the Variables dictionary.

        **Purpose**
        This function processes the "ExperimentSettings" string from the provided dictionary
        and converts its content into key-value pairs. It then updates the dictionary by
        merging these key-value pairs into the main dictionary and removing the original
        "ExperimentSettings" key. This helps organize and simplify the structure of
        configuration or settings data.

        **Inputs**
        - `Variables`: A dictionary that may contain an "ExperimentSettings" key with a
        string of settings in a specific format.

        **Outputs**
        - `Variables`: The updated dictionary with the settings extracted and added as
        individual key-value pairs, and the original "ExperimentSettings" key removed.

        **Requirements**
        - **None**: The function utilizes basic Julia operations and does not rely on any
        external packages.
"""
function ExpSett2Dict( Variables::Dict )
    # Check if the "ExperimentSettings" key exists in the dictionary.
    if "ExperimentSettings" in keys( Variables )
        # Retrieve the value associated with the "ExperimentSettings" key.
        ExperimentSettings = Variables[ "ExperimentSettings" ];
        # Split the settings string by line breaks.
        t = split( ExperimentSettings, "\r\n" );
        # Remove unwanted characters (spaces, braces, and quotes) from the settings lines.
        t = replace.( t, r"  |{|}|\x22" => "" );
        # Filter out lines that do not contain alphabetic characters.
        t = [ i for i in t if !isempty( eachmatch( r"[a-z]", i ) ) ];
        # Split each remaining line by the colon and space delimiter.
        t = split.( t, ": " );
        # Initialize an empty dictionary to store the extracted key-value pairs.
        D = Dict{ String, Any }( );
        # Process each key-value pair extracted from the settings string.
        for i in t
            if i[ 2 ] != ""
                # Remove unwanted characters (commas, brackets, and spaces) from the value.
                aux = replace( i[ 2 ], r",|\[|\]|\[\]| " => "" );
                if aux != ""
                    # Attempt to parse the value as a Float64. If parsing fails, leave the
                    # value as a string.
                    try
                        aux = parse( Float64, aux );
                    catch e
                    end
                    # Add the key-value pair to the dictionary.
                    D[ i[ 1 ] ] = aux;
                end
            end
        end
        # Remove the "ExperimentSettings" key from the original dictionary.
        delete!( Variables, "ExperimentSettings" );
        # Merge the extracted key-value pairs into the original dictionary.
        Variables = merge( Variables, D );
    end
    # Return the updated dictionary.
    return Variables
end

"""
    CleanDictionary( D::Dict ) → D::Dict
        Removes specific types of entries from a dictionary. It deletes entries based on the
        value's content, excluding those with `Symbol` type values.

        **Purpose**
        This function cleans a dictionary by removing entries where:
        - The value is the string `"null"`.
        - The value is an empty string.
        - The value is an empty array.
        - The value is a default empty value obtained from `get()`
        (when a key might not exist)

        `Symbol` type values are preserved and not processed or removed.

        **Inputs**
        - `D`: A dictionary where the function examines each entry and applies the cleanup
        criteria.

        **Outputs**
        - `D`: The cleaned dictionary with irrelevant or empty entries removed.

        **Requirements**
        - **None**: The function uses basic Julia operations and does not require any
        external packages.
"""
function CleanDictionary( D::Dict )
    # Iterate over each key in the dictionary.
    for k in keys( D )
        # Skip processing if the value is of type Symbol.
        if typeof( D[ k ] ) == Symbol
            continue
        else
            # Check conditions for removal:
            # 1. Value is the string "null".
            c1 = D[ k ] == "null";
            # 2. Value is an empty string.
            c2 = D[ k ] == "";
            # 3. Value is an empty array (for array types).
            c3 = isempty( D[ k ] );
            # 4. Value is a default empty array obtained from `get()`.
            c4 = isempty( get( D, k, [ ] ) );
            # If any condition is met, delete the entry from the dictionary.
            if ( c1 || c2 || c3 || c4 )
                delete!( D, k );
            end
        end
    end
    # Return the cleaned dictionary.
    return D
end

"""
    right_now() → time_stamp::String
        Creates a label with the current date and time, rounded to the nearest 15 minutes,
        formatted according to RFC 1123.

        **Purpose**
        This function generates a timestamp representing the current date and time. The
        timestamp is rounded to the nearest 15 minutes and formatted in RFC 1123 format,
        which is commonly used in HTTP headers and other applications requiring a
        standardized date format.

        **Inputs**
        - None: This function does not take any input parameters.

        **Outputs**
        - `time_stamp`: A string containing the current date and time formatted according to
        RFC 1123.

        **Requirements**
        - **Native Modules**: `Dates`
"""
function right_now( )
    # Get the current date and time.
    current_time = Dates.now( );
    # Round the current time to the nearest 15 minutes.
    rounded_time = round( Dates.DateTime( current_time ), Dates.Minute( 15 ) );
    # Format the rounded time according to RFC 1123 format.
    time_stamp = Dates.format( rounded_time, Dates.RFC1123Format );
    # Return the formatted time stamp as a string.
    return time_stamp
end

"""
    GetVarsHDF5( FILEBRW::String ) → Variables::Dict
        Reads the contents of an HDF5 file, processes the data, and generates various outputs
        including a JLD2 file with extracted information, a text report, and a `Variables`
        dictionary for further manipulation.

        **Purpose**
        This function opens an HDF5 file, extracts and processes its data to create a
        comprehensive report and save key information in a `.jld2` file. It converts paths to
        relative, extracts and cleans variables, calculates dataset sizes, and generates a
        detailed report including analysis results and metadata.

        **Inputs**
        - `FILEBRW`: A string representing the absolute path to the HDF5 file that will be
        read and processed.

        **Outputs**
        - `Variables`: A dictionary containing the processed and extracted data from the HDF5
        file, including metadata and analysis results.

        **Requirements**:
        - **Custom Functions**: `HDF5Content`, `ExtractRawDataset`, `ExtractValues`,
        `Abs2RelPath`, `ExpSett2Dict`, `ExpDate2Str`, `CleanDictionary`.
        - **Native Modules**: `JLD2`, `HDF5`, `InteractiveUtils`, `Suppressor`, `Dates`.
"""
function GetVarsHDF5( FILEBRW::String )
    # Open the HDF5 file for reading.
    BRW = h5open( FILEBRW, "r" );
    # Extract groups and attributes from the HDF5 file.
    GroupsHDF5, AttrHDF5 = HDF5Content( BRW );
    # Identify the raw dataset ( biggest ) and all other datasets.
    ΔΣ, nΔΣ = ExtractRawDataset( BRW, GroupsHDF5 );
    # Extract values from the HDF5 file, excluding the raw dataset.
    Variables = ExtractValues( BRW, AttrHDF5, nΔΣ );
    # Convert absolute paths in the dictionary to relative paths.
    Variables = Abs2RelPath( Variables );
    # Process "ExperimentSettings" if it exists in the dictionary.
    if "ExperimentSettings" in keys( Variables )
        Variables = ExpSett2Dict( Variables );
        Variables = ExpDate2Str( Variables );
    end
    # Clean the dictionary by removing empty or invalid entries.
    Variables = CleanDictionary( Variables );
    # Calculate the file size in GB.
    filesize = round( ( stat( FILEBRW ).size ) / ( 1024 ^ 3 ), digits = 2 );
    # Access the raw dataset and calculate its size.
    dset = BRW[ ΔΣ ];
    dsetsize = deepcopy( filesize );
    try
        # Calculate the size of the dataset only, in GB.
        dsetsize = ( sizeof( dset[ 1 ] ) * size( dset )[ 1 ] ) / ( 1024 ^ 3 );
    catch e
        # Handle errors and calculate dataset size based on a sample read.
        a, b = size( dset );
        onenumber = h5read( FILEBRW, ΔΣ, ( 1, 1 ) );
        dsetsize = ( sizeof( onenumber ) * a * b ) / ( 1024 ^ 3 );
    end
    # Add dataset and file information to the Variables dictionary.
    Variables[ "RAW" ] = ΔΣ;
    Variables[ "BRWNAME" ] = BRW.filename;
    Variables[ "dsetsize" ] = dsetsize;
    try
        # Determine the number of channels.
        Variables[ "nChs" ] = length( Variables[ "Chs" ] );
    catch e
        Variables[ "nChs" ] = 4096;
    end
    # Calculate the number of recorded frames if not already present.
    if !( "NRecFrames" in keys( Variables ) )
        a, b = size( dset );
        if a == 4096
            Variables[ "NRecFrames" ] = b;
        else
            Variables[ "NRecFrames" ] = size( dset, 1 ) / Variables[ "nChs" ];
        end
    end
    # Calculate the BWR time based on the number of frames and sampling rate.
    BRWTIME = round(
        ( Variables[ "NRecFrames" ] / Variables[ "SamplingRate" ] ), digits = 3 );
    Variables[ "BRWTIME" ] = BRWTIME;
    # Define paths for saving the JLD2 file and text report.
    PATHBRWs = dirname( FILEBRW );
    PATHMAIN = joinpath( dirname( PATHBRWs ), split( basename( FILEBRW ), "." )[ 1 ] );
    PATHINFO = joinpath( PATHMAIN, "Info" );
    mkpath( PATHINFO );
    cd( PATHMAIN );
    FILEVARIABLES = joinpath( PATHINFO, "Variables.jld2" );
    # Save the Variables dictionary to a JLD2 file.
    jldsave( FILEVARIABLES; Variables );
    # Generate and print a report with information about the file and analysis.
    seg0 = "# --------------------------------------------------";
    segN = "-------------------------------------------------- #";
    println( seg0, " Report ", segN );
    println( "File: ", replace( BRW.filename, homedir( ) => "~" ) );
    println( "Description: ", Variables[ "Description" ] );
    println( "HDF5 file size: $filesize GB, corresponding to $BRWTIME seconds" );
    println( "Date of Analysis: ", right_now( ), " by ", basename( homedir( ) ) );
    println( "You are now working on the new main path: ", PATHMAIN );
    println( seg0, "--------", segN );
    # Capture the report output.
    output = @capture_out begin
        println( seg0, " Report ", segN );
        println( "File: ", replace( BRW.filename, homedir( ) => "~" ) );
        println( "Description: ", Variables[ "Description" ] );
        println( "HDF5 file size: $filesize GB, corresponding to $BRWTIME seconds" );
        println( "Date of Analysis: ", right_now( ), " by ", basename( homedir( ) ) );
        println( "With:\n", string( basename( homedir( ) ), "@", gethostname( ) ) );
        versioninfo( );
        println( seg0, "--------", segN );
    end
    # Write the report to a text file.
    FILEINFO = joinpath( PATHINFO, "Reporte.txt" );
    write( FILEINFO, output );
    # Close the HDF5 file.
    close( BRW );
    # Return the Variables dictionary.
    return Variables
end

"""
    GetChunkSize( Variables::Dict, MaxGB::Real = 0.5, m::Int = 3, M::Int = 500 ) → σ::Int
        Determines the optimal number of segments for a dataset such that each segment's size
        does not exceed `MaxGB`. It also ensures that the number of segments falls within the
        range specified by `m` and `M`, where `m` is the minimum and `M` is the maximum
        number of segments allowed. If a suitable number of segments cannot be determined,
        defaults to dividing the dataset into segments of 4 seconds each.

        **Purpose**
        This function calculates how to partition a dataset into manageable segments based on
        its size and specified constraints. It helps in managing large datasets by ensuring
        that each segment is of a feasible size for processing or analysis, while also
        adhering to constraints on the number of segments.

        **Inputs**
        - `Variables`: A dictionary containing metadata about the hdf5 original file,
            including:
            - `"NRecFrames"`: Total number of frames in the dataset.
            - `"dsetsize"`: Size of the dataset in gigabytes.
            - `"nChs"`: Number of channels in the dataset.
            - `"SamplingRate"`: Sampling rate of the dataset.
        - `MaxGB`: The maximum allowed size for each segment in gigabytes (default is 0.5 GB)
        - `m`: Minimum number of segments (default is 3).
        - `M`: Maximum number of segments (default is 500).

        **Outputs**
        - `σ`: The number of segments that meet the size constraints.

        **Requirements**
        - **Native Modules**: `Primes`
"""
function GetChunkSize( Variables::Dict, MaxGB::Real = 0.5, m::Int = 3, M::Int = 500 )
    flagQtUI = 0;
    # Retrieve dataset properties from the Variables dictionary
    NRecFrames = Variables[ "NRecFrames" ];
    dsetsize = Variables[ "dsetsize" ];
    nChs = Variables[ "nChs" ];
    SamplingRate = Variables[ "SamplingRate" ];
    # Calculate the size of one frame in gigabytes
    onenumber = dsetsize / ( NRecFrames * nChs );
    # Adjust the number of frames to avoid prime values
    while isprime( NRecFrames )
        NRecFrames -= 1;
        dsetsize -= onenumber;
    end
    # Find divisors of the number of frames within the specified range
    divs = divisors( NRecFrames );
    divs = divs[ divs .>= m .&& divs .<= M ];
    # Calculate the size of each segment for the valid divisors
    aux = dsetsize ./ divs;
    aux = aux[ aux .<= MaxGB ];
    finalsize = 0;
    σ = 0;
    # Determine if a suitable segment size is found
    if isempty( aux )
        flagQtUI = 1;
        m1 = "No optimal segment size has been found for the 'MaxGB' value. ";
        m2 = "Using default segment length of 4 seconds.";
        println( m1, m2 );
        σ = floor( Int, NRecFrames / SamplingRate * 4 ); # Default to 4 seconds per segment
        nfrs = floor( Int, NRecFrames / σ );
        NRecFrames = Int( nfrs * σ );
        finalsize = nfrs * nChs * onenumber;
    else
        finalsize = maximum( aux );
        σ = Int( dsetsize / finalsize );
    end
    # Calculate the time duration of each segment
    finaltime = ( ( NRecFrames / σ ) / SamplingRate );  # in seconds
    fs = round( finalsize, digits = 3 );  # Size of each segment in GB
    ft = round( finaltime, digits = 3 );  # Duration of each segment in seconds
    # Print segment information
    println( "$σ segments of $fs GB and $ft seconds each" );
    return σ, ft, fs, flagQtUI
end

"""
    OneSegment( RAW::HDF5.Dataset, Variables::Dict, n::Int, N::Int ) → BIN::Array{ UInt16 }
        Extracts the n-th segment from the provided dataset and returns it as a 2D array.

        **Purpose**
        This function extracts a specific segment (n-th segment) from the given dataset, 
        where the dataset is already loaded into memory (represented by `RAW`). It divides 
        the entire dataset into `N` segments and returns the n-th segment, which is useful 
        for analyzing a portion of the dataset at a time.

        **Inputs**
        - `RAW`: The dataset that has already been loaded from an HDF5 file. It is assumed to
            be either a 2D array (nChs x frames) or a 1D array (newer formats).
        - `Variables`: A dictionary containing metadata about the dataset, including:
            - `"NRecFrames"`: The total number of recording frames in the dataset.
            - `"nChs"`: The number of channels in the dataset.
        - `n`: The index of the segment to be extracted (1-based).
        - `N`: The total number of segments the dataset is divided into.

        **Outputs**
        - `BIN`: A 2D array of type `UInt16` representing the extracted segment, with
            dimensions `[nChs, nfrs]`, where `nChs` is the number of channels and `nfrs` is 
            the number of frames in the segment.

        **Requirements**
        - The dataset `RAW` must already be loaded before calling the function, either in the
          form of an array or a view of an HDF5 dataset.
"""

function OneSegment( RAW::HDF5.Dataset, Variables::Dict, n::Int, N::Int )
    # Extract metadata from the Variables dictionary
    NRecFrames = Variables[ "NRecFrames" ]; # Total number of recording frames in the dataset
    nChs = Variables[ "nChs" ];             # Number of channels in the dataset
    # Determine the number of frames per segment by dividing total frames by N segments
    nfrs = floor( Int, ( NRecFrames / N ) ); # nfrs: Number of frames in each segment
    # Initialize the BIN array, which will store the extracted segment
    # Attempt to retrieve the dimensions of the dataset (RAW)
    # RAW can either be a 2D array (channels x frames) or a 1D array (frames x channels)
    nchs = 0;
    nFrs = 0;
    try
        nchs, nFrs = size( RAW );  # Try to get the shape of the dataset
    catch e
        # If the dataset is 1D, treat it as a vector and assign size accordingly
        nchs = 1;
        nFrs = length( RAW );
    end
    # Extract the n-th segment based on the dataset format
    if nchs == nChs && nchs != 0
        # Case 1: Dataset has an nChs x nFrs form (older format with separate channels)
        # Calculate frame range for the n-th segment
        fr0 = ( ( n - 1 ) * nfrs ) + 1; # Start frame index for the n-th segment
        frN = n * nfrs; # End frame index for the n-th segment
        # Extract frames from RAW for all channels between fr0 and frN
        BIN = view( RAW, 1:nChs, fr0:frN );
    elseif nFrs == ( NRecFrames * nChs ) && nFrs != 0
        # Case 2: Dataset is in vector form (newer format where all frames are stored as a 
        # single array)
        # Instead of looping through frames, use reshape to extract the segment
        init = ( n - 1 ) * nfrs * nChs + 1;  # Starting index for the n-th segment
        endit = n * nfrs * nChs;              # Ending index for the n-th segment
        # Extract and reshape into [nChs, nfrs] format
        BIN = reshape( RAW[ init:endit ], nChs, nfrs );
    end
    # Return the extracted segment as a 2D, UInt16 array
    return BIN
end

"""
    Digital2Analogue( Variables::Dict, DigitalValue::Matrix{ UInt16 } ) ⤵
        → BIN::Matrix{ Float64 }

        Converts digital ΔΣ data extracted from a brw file to voltage values (μV) using a
        specified conversion formula. The conversion formula is:
            Voltage = ( DigitalValue + ADCCountsToMV ) * MVOffset
        The result is a matrix of voltage values.

        **Purpose**
        This function transforms digital values from the ΔΣ data into analog voltage values.
        It utilizes parameters from the `Variables` dictionary to perform the conversion,
        which is useful for interpreting and analyzing digital data in terms of real-world
        voltage measurements.

        **Inputs**
        - `Variables`: A dictionary containing conversion parameters:
            - `"SignalInversion"`: A factor indicating if the signal should be inverted.
            - `"MinVolt"`: The minimum voltage corresponding to the digital value range.
            - `"MaxVolt"`: The maximum voltage corresponding to the digital value range.
            - `"BitDepth"`: The bit depth of the ADC used to convert the analog signal to
                digital.
        - `DigitalValue`: A matrix of type `UInt16` representing the digital ΔΣ data.

        **Outputs**
        - `BIN`: A matrix of type `Float64` where each element represents the converted
        voltage value.

        **Requirements**
        - **None**: The function uses basic Julia operations and does not require any
        external packages.
"""
function Digital2Analogue( Variables::Dict, DigitalValue::Matrix{ UInt16 } )
    # Retrieve conversion parameters from the Variables dictionary
    SignalInversion = Variables[ "SignalInversion" ];
    MinVolt = Variables[ "MinVolt" ];
    MaxVolt = Variables[ "MaxVolt" ];
    BitDepth = Variables[ "BitDepth" ];
    # Calculate the voltage offset and ADC counts to voltage conversion factor
    MVOffset = SignalInversion * MinVolt;
    ADCCountsToMV = ( SignalInversion * ( MaxVolt - MinVolt ) ) / ( 2 ^ BitDepth );
    # Convert the digital values to analog voltage values using the specified formula
    BIN = @. MVOffset + ( DigitalValue * ADCCountsToMV );
    # Return the converted matrix of voltage values
    return BIN
end

"""
    SupInfThr( Data::Array, Thr::Real ) → Cols::Vector, Rows::Vector
        Identifies the columns and rows of values in the array that are above a specified
        threshold or below its negative counterpart. The result is organized by columns and
        rows where the values exceed the threshold.

        **Purpose**
        This function locates and organizes the positions of elements in a 2D array that meet
        or exceed a certain magnitude threshold. It is useful for analyzing and extracting
        data points of interest based on their magnitude.

        **Inputs**
        - `Data`: A 2D array containing the numerical data to be analyzed.
        - `Thr`: A real number representing the magnitude threshold. The function will find
        values greater than or equal to `Thr` or less than or equal to `-Thr`.

        **Outputs**
        - `Cols`: A vector containing the column indices of the data points that meet the
        threshold condition.
        - `Rows`: A vector containing the corresponding row indices of the data points.

        **Requirements**
        - **None**: The function uses basic Julia operations and does not require any
        external packages.
"""
function SupInfThr( Data::Array, Thr::Real )
    # Find indices of elements in the array where the absolute value is greater than or equal
    # to the threshold
    SIT = findall( abs.( Data ) .>= Thr );
    # Extract column and row indices from the positions found
    AllCols = getindex.( SIT, [ 1 ] );
    AllRows = getindex.( SIT, [ 2 ] );
    # Initialize vectors to store unique columns and corresponding rows
    Rows = [ ];
    Cols = [ ];
    # Iterate through unique column indices and organize the rows for each column
    for col in sort( unique( AllCols ) )
        push!( Rows, AllRows[ AllCols .== col ] );
        push!( Cols, col );
    end
    return Cols, Rows
end

"""
    UniqueCount( Data::Array ) → Count::Vector{ Int64 }
        Counts the number of unique values for each row of an array.
        This function measures the cardinality of each row, which refers to the number of
        distinct elements in a dataset. Cardinality is a concept commonly used in data
        analysis to describe the uniqueness or diversity of values within a particular set.

        **Purpose**
        This function computes the number of unique values in each row of a given 2D array.
        The resulting counts represent how many distinct values exist per row, which is
        useful for understanding the diversity or variability within rows of data.

        **Inputs**
        - `Data`: A 2D array where each row's unique values are counted.

        **Outputs**
        - `Count`: A vector containing the count of unique values for each row in the input
        array.

        **Requirements**
        - **None**: The function uses basic Julia operations and does not require any
        external packages.
"""
function UniqueCount( Data::Array )
    # Get the dimensions of the input array
    N, _ = size( Data );
    # Initialize an array to hold the count of unique values for each row
    Count = Array{ Int64 }( undef, N );
    # For each row, compute the number of unique values (after rounding to 2 decimal places)
    [ Count[ n ] = length( unique( round.( Data[ n, : ], digits = 2 ) ) ) for n in 1:N ];
    return Count
end

"""
    STDΔV( Variables::Dict, BIN::AbstractMatrix{ T }, ΔT::Real = 250 ) ⤵
        → STD::Vector{ Float64 }
        Calculates the standard deviation of voltage shifts within a dataset, with ΔT
        specified in milliseconds.

        **Purpose**
        This function computes the standard deviation of voltage shifts within a dataset.
        The deviation is calculated by shifting the dataset by a specified time interval, ΔT,
        and measuring how much the voltage values deviate. This analysis is useful for
        assessing signal stability and variations over time.

        **Inputs**
        - `Variables`: A dictionary containing parameters necessary for time conversion. It
        should include parameters for converting milliseconds to frames.
        - `BIN`: A 2D array (matrix) containing voltage values for which the deviations are
        calculated. The array should be of type `AbstractMatrix{T}` where `T` can be any
        numeric type.
        - `ΔT`: The time shift in milliseconds. This parameter determines how much the
        dataset is shifted when calculating deviations. The default value is 250
        milliseconds.

        **Outputs**
        - `STD`: A vector of type `Float64` containing the standard deviations of voltage
        shifts for each row in the dataset. The vector represents the amount of deviation
        observed in voltage values across time shifts.

        **Requirements**
        - **Custom Functions**: `ms2frs` – A function that converts milliseconds to the
        corresponding number of frames based on the dataset’s parameters.
        - **Native Modules**: `StatsBase` – Provides statistical functions including `std`
        for calculating standard deviations.
"""
function STDΔV( Variables::Dict, BIN::AbstractMatrix{ T }, ΔT::Real = 250 ) where T
    # Convert the BIN array to Float64 for precise calculations if needed
    BIN = convert( Matrix{ Float64 }, BIN );
    # Convert ΔT from milliseconds to frames using the ms2frs function
    ΔT = ms2frs( ΔT, Variables );
    # Check if ΔT is within valid range
    if ΔT <= 0 || ΔT >= size( BIN, 2 )
        throw( ArgumentError(
            "ΔT must be within the range of the dataset's time dimension." ) );
    end
    # Compute the standard deviation of voltage shifts
    shifted_BIN = circshift( BIN, ( 0, ΔT ) );
    voltage_shifts = shifted_BIN .- BIN;
    std_dev = std( voltage_shifts, dims = 2 );
    # Extract the result as a vector
    STD = std_dev[ : ];
    return STD
end

"""
    ms2frs( time::Real, SamplingRate::Real OR Variables::Dict ) → frs::Int
        Converts milliseconds to frames based on the sampling rate of the file.

        **Purpose**
        This function converts a time duration given in milliseconds to a number of frames.
        The conversion takes into account the sampling rate of the data, which determines how
        frequently samples are taken. The function can handle either a direct sampling rate
        value or retrieve it from a dictionary of variables.

        **Inputs**
        - `time`: The time duration in milliseconds that needs to be converted to frames.
        - `SamplingRate`: The sampling rate of the data, which specifies how many frames are
        captured per second. This is used when the sampling rate is provided directly.
        - `Variables`: A dictionary containing the sampling rate under the key
        `"SamplingRate"`. This is used if the sampling rate is not provided directly.

        **Outputs**
        - `frs`: The number of frames corresponding to the given time duration.

        **Requirements**
        - **None**: The function uses basic Julia operations and does not require any
        external packages.
"""
function ms2frs( time::Real, SamplingRate::Real )
    return ceil( Int, ( time * SamplingRate ) / 1000 );
end
function ms2frs( time::Real, Variables::Dict )
    SamplingRate = Variables[ "SamplingRate" ];
    return ceil( Int, ( time * SamplingRate ) / 1000 );
end
# ----------------------------------------------------------------------------------------- #
#                                       Module STEP01_v1
# ----------------------------------------------------------------------------------------- #
"""
    SearchDir( path::String, key::String ) → list::Vector{ String }
"""
SearchDir( path::String, key::String ) = filter( x -> endswith( x, key ), readdir( path; join = true ) );

"""
    LoadDict( filename::String ) → D::Dict
        # Native
        using JLD2
"""
function LoadDict( filename::String )
    D = load( filename );
    K = keys( D );
    if length( K ) == 1
        k = collect( K )[ 1 ];
        D = D[ k ];
    end
    return D
end

"""
    BarPlot( W::VecOrMat, fc::Symbol = :royalblue3, t::String = "", xl::String = "", yl::String = "" ) → Plot
        # Native
        using Plots, Measures
"""
function BarPlot( W::VecOrMat, fc::Symbol = :royalblue3, t::String = "", xl::String = "", yl::String = "" )
    P = plot( );
    P = bar( W,
        leg = :none,
        fillcolor = fc,
        lc = :white,
        grid = :none,
        wsize = ( 600, 400 ),
        title = t,
        top_margin = 10mm,
        dpi = 300,
        xlabel = xl,
        ylabel = yl,
        left_margin = 5mm,
        bottom_margin = 5mm,
        );
    return P
end

"""
    SupThr( Data::Array, Thr::Real ) → Cols::Vector, Rows::Vector
        Find values above Thr and below -Thr. Organized on Columns and Rows
"""
function SupThr( Data::Array, Thr::Real )
 ST = findall( abs.( Data ) .>= Thr );
    AllCols = getindex.( ST, [ 1 ] );
    AllRows = getindex.( ST, [ 2 ] );
    Rows = [ ];
    Cols = [ ];
    for col in sort( unique( AllCols ) )
        push!( Rows, AllRows[ AllCols .== col ] );
        push!( Cols, col )
    end
    return Cols, Rows
end

"""
    ReduceArrayDistance( W::Vector, distance::Int64 ) → G::Array
        Groups contiguous numbers with maximum distance between them “distance”.
"""
function ReduceArrayDistance( W::Vector, distance::Int64 )
    g = [ ];
    W = sort( unique( W ) );
    for w0 in W
        r = collect( w0 :( w0 + distance ) );
        push!( g, W[ W .∈ [ r ] ] );
    end
    G = [ ];
    push!( G, g[ 1 ] );
    for i = 2:length( g )
        if isempty( intersect( g[ i ], G[ end ] ) )
            push!( G, g[ i ] );
        else
            G[ end ] = sort( union( g[ i ], G[ end ] ) );
        end
    end
    return G
end

"""
    Neighbours( C::Int64, d::Int64 ) → A::Array{ Int64 }, v::Vector{ Int64 }
        A = Array( ( d*2 ) + 1, ( d * 2 ) + 1 ),
        v = vec( 2*( ( d * 2 ) + 1 ) - 1 );
        The d-neighborhood is calculated from the channel ( C ) as a center
        A = array where C is the center and is in chip order
        v = same neighboring channels as A but in vector form and without C ( 8 channels for d = 1 )
"""
function Neighbours( center::Int64, d::Int64 )
    Layout = reverse( reshape( collect( 1:4096 ), 64, 64 )', dims = 1 );
    x = findall( Layout .== center )[ ][ 2 ];
    y = findall( Layout .== center )[ ][ 1 ];
    aux = [ ( x - d ),( x + d ), ( y - d ), ( y + d ) ];
    aux[ aux .< 1 ] .= 1;
    aux[ aux .> 64 ] .= 64;
    A = Layout[ aux[ 3 ]:aux[ 4 ], aux[ 1 ]:aux[ 2 ] ];
    v = vec( A )[ vec( A ) .!= center ];
    return A, sort( v )
end

"""
    Fences( data::Vector ) → LowerFence::Real, HigherFence::Real
        Simple test for Outliers
        # Native
        using StatsBase
"""
function Fences( data::Vector )
    Q1 = quantile( data, 0.25 );
    Q3 = quantile( data, 0.75 );
    IQR = Q3 - Q1;
    LF = Q1 - 1.5*IQR;
    HF = Q3 + 1.5*IQR;
    return LF, HF
end

"""
    ReconstructChannels( data::Array, lim = 10 ) → fictional_channel::Vector
        Creates an vector form an array in the following order: "mean", "median", "n random samples"
        testing the std form the array vs the resultant vector. If the std form the vector is an
        outlier acordingly on the fences test, then the next vector is determined. If is necesary to
        take n random samples, the limit number of times is set by the user
        # Custom
        using Fences
        # Native
        using StatsBase
"""
function ReconstructChannels( data::Array, lim = 10 )
    _, nFrs = size( data );
    STDS = vec( std( data, dims = 2 ) );
    LF, HF = Fences( STDS )
    C = 0;
    fictional_channel = vec( mean( data, dims = 1 ) );
    s = std( fictional_channel );
    test = ( s > LF && s < HF );
    if test == false
        fictional_channel = vec( median( data, dims = 1 ) );
        s = std( fictional_channel );
        test = ( s > LF && s < HF );
        if test == false
            while test == false && C < lim
                fictional_channel = sample( data, nFrs );
                s = std( fictional_channel );
                test = ( s > LF && s < HF );
                C = C + 1;
            end
        end
    end
    return fictional_channel
end

"""
    PatchEmpties( aux::Vector, Empties::Vector = [ ] ) → aux::Vector
        Replaces the aux vector values in the Empties vector positions with random non-Empties aux values.
        For graphing purposes only.
        # Native
        using StatsBase
"""
function PatchEmpties( aux::Vector, Empties::Vector = [ ] )
    nChs = length( aux );
    NotEmpties = setdiff( 1:nChs, Empties );
    nv = sample( NotEmpties, length( Empties ) );
    aux[ Empties ] = aux[ nv ];
    return aux
end

"""
    Zplot( W::VecOrMat, cm_::Symbol, t::String, c::Real = 0 ) → P::Plot
        Plot a square heatmap, gr backend, cm_ colormap with title "t", cbarlims = c
        If the color bar limits are not defined (c), it will be set to ± ( media + 2*std ) of W
        # Native
        using Plots, Measures, StatsBase
"""
function Zplot( W::VecOrMat, cm_::Symbol = :vik, forGUI::Bool = true, t::String = "", c::Real = 0 )
    W = vec( W );
    nc = Int( sqrt( length( W ) ) );
    Z = reverse( reshape( W, nc, nc )', dims = 1 );

    if c == 0
        c = median( W ) + ( 2 * std( W ) );
    end
    
    Plots.gr( );
    P = plot( );

    if ( forGUI )
        P = heatmap(
            Z,
            wsize = ( 400, 400 ),
            axis = ( [ ], false ),
            fillalpha = 1.0,
            clims = ( -c, c ),
            colormap = cm_,
            aspect_ratio = :equal,
            cbar = :none,
            );
    else
        P = heatmap(
            Z,
            wsize = ( 400, 400 ),
            axis = ( [ ], false ),
            title = t,
            titlefontsize = 10,
            cbarfontsize = 10,
            dpi = 300,
            fillalpha = 1.0,
            right_margins = 5mm,
            clims = ( -c, c ),
            colormap = cm_,
            aspect_ratio = :equal,
            lims = ( 0, nc + 1 ),
        );
    end

    return P
end

# ----------------------------------------------------------------------------------------- #
#                                   Jorgio functions
# ----------------------------------------------------------------------------------------- #
function Channel_Spectrogram( BINRAW::Matrix{Float64}, channel::Int64, n1::Int64, n_overlap1::Int64 )
    fs = 17855.55;
    signal = Float32.( BINRAW[channel, :] );
    spectro1 = mt_spectrogram( signal, n1, n_overlap1, fs=fs );
    time = ( 0:length( signal ) - 1) / fs;

    bands = Dict(
        :delta => (0, 5),
        :theta => (4, 8),
        :alpha => (8, 12)
    );

    function extract_band_data(spectro, band_range)
        band_indices = findall(x -> band_range[1] <= x <= band_range[2], spectro.freq);
        freq_data = spectro.freq[band_indices];
        power_data = abs.(spectro.power[band_indices, :]);
        avg_power = mean(spectro.power[band_indices, :], dims=1);
        std_power = std(spectro.power[band_indices, :], dims=1);
        power_data_norm = abs.((power_data .- avg_power) ./ std_power);
        power_data_norm_avg = vec(mean(power_data_norm, dims=1));
        return freq_data, power_data_norm_avg
    end

    freq_data_delta, power_data_delta_norm_avg = extract_band_data(spectro1, bands[:delta]);
    freq_data_theta, power_data_theta_norm_avg = extract_band_data(spectro1, bands[:theta]);
    freq_data_alpha, power_data_alpha_norm_avg = extract_band_data(spectro1, bands[:alpha]);

    # Normalize each data set so that its maximum value is 1
    delta_norm = power_data_delta_norm_avg ./ maximum(power_data_delta_norm_avg)
    theta_norm = power_data_theta_norm_avg ./ maximum(power_data_theta_norm_avg)
    alpha_norm = power_data_alpha_norm_avg ./ maximum(power_data_alpha_norm_avg)

    p = plot(
        plot(time, signal,
            xlabel="Time (s)", ylabel="Amplitude (μV)", legend=false, label=false),
        plot(spectro1.time, delta_norm,
            xlabel="Time (s)", ylabel="Normalized Power", legend=false, label=false),
        plot(spectro1.time, theta_norm,
            xlabel="Time (s)", ylabel="Normalized Power", legend=false, label=false),
        plot(spectro1.time, alpha_norm,
            xlabel="Time (s)", ylabel="Normalized Power", legend=false, label=false),
        layout = @layout([a; b; c; d]), 
        title=["Original signal from channel $channel" "Delta Band (0-5 Hz)" "Theta Band (4-9 Hz)" "Alpha Band (8-12 Hz)"],
        wsize = (800, 800)
    );

    return p
end

# ----------------------------------------------------------------------------------------- #
#                              Julia auxiliar functions for Qt
# ----------------------------------------------------------------------------------------- #
"""
    ChunkSizeSpace( Variables::Dict, limupper::Real ) -> σ::Int
        Determina el numero de segmentos en los que el dataset se debe recortar considerando el tamano en espacio de disco que ocupara cada uno. limupper es el tamano maximo establecido por el usuario en GB.
"""
function optimal_file_size(Variables::Dict, limupper::Real)
    NRecFrames = Variables["NRecFrames"]
    σ = max(1, Int(floor(Variables["dsetsize"] / limupper)))
    finalsize = Variables["dsetsize"] / σ
    upper_tolerance = limupper * 1.15
    flagQtUI = 0

    if finalsize > limupper && finalsize < upper_tolerance && NRecFrames % σ != 0
        return finalsize, σ, flagQtUI
    elseif finalsize > upper_tolerance
        while finalsize > upper_tolerance && NRecFrames % σ != 0
            σ += 1
            finalsize = Variables["dsetsize"] / σ
        end
        if finalsize > upper_tolerance
            σ = Int(ceil(NRecFrames / (Variables["SamplingRate"] * 2)))
            finalsize = Variables["dsetsize"] / σ
            flagQtUI = 1
            println("No optimal segment size found for limupper set, setting default segment duration to 2 seconds")
        end
    end

    return finalsize, σ, flagQtUI
end


function ChunkSizeSpace(Variables::Dict, limupper::Real)
    finalsize, σ, flagQtUI = optimal_file_size(Variables, limupper)
    fs, ft = round.([finalsize, (Variables["NRecFrames"] / σ) / Variables["SamplingRate"]], digits=3)
    println("$σ segments of $fs GB and $ft seconds each")
    return σ, ft, fs, flagQtUI
end

"""
    convgauss( sigma::Real, h::Vector ) -> hg::Vector'
        Convolution between a gaussian function and a vector
"""
function convgauss( sigma::Real, h::Vector )
    cte = ( 1 / ( sigma * sqrt( 2 * pi ) ) );
    potencia( x ) = -( ( x ^ 2 ) / ( 2 * ( sigma ^ 2 ) ) );
    gx( x ) = cte * exp( potencia( x ) );
    g = gx.( h );
    hg = h .* g;
    return hg
end

"""
    RemoveInfs( data::VecOrMat )
        Remove the -Infs and Infs entries. Replace with maximum and minimum nonInf value
"""
function RemoveInfs( data::VecOrMat )
    m = minimum( data[ data .!= -Inf ] );
    M = maximum( data[ data .!= Inf ] );
    data[ data .== -Inf ] .= m;
    data[ data .== Inf ] .= M;
    return data
end

# ----------------------------------------------------------------------------------------- #
end # module AllSTEPs
# ----------------------------------------------------------------------------------------- #