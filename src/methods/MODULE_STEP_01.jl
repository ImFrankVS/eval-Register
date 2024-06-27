# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
module MODULE_STEP_01
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
using HDF5
using Dates
using JLD2
using StatsBase
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
export FindContent
export GetVarsHDF5
export ChunkSizeSpace
export ChunkSizeSpaceGraph
export OneSegment
export Digital2Analogue
export UniqueCount
export Desaturation
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
export Neighbors
export GetGroupsHDF5
export GetAttrHDF5
export HDF5Content
export ExtractRawDataset
export ExtractValues
export ExpDate2Str
export ExpSett2Dict
export CleanDictionary
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #



# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    FindContent( thing::String, FILEBRW::String = "", WORKDIR::String = "" )
"""
function FindContent( thing::String, FILEBRW::String = "", WORKDIR::String = "" )
    if FILEBRW != ""
        WORKDIR = joinpath(
            splitdir( dirname( FILEBRW ) )[ 1 ], splitext( basename( FILEBRW ) )[ 1 ] );
    end
    Result = [ ];
    for ( root, dirs, files ) in walkdir( WORKDIR )
        for file in files
            push!( Result, joinpath( root, file ) ); # path to files
        end
    end
    Result = Result[ occursin.( thing, Result ) ];
    if length( Result ) == 1
        Result = Result[ 1 ];
    end
    return Result
end



"""
    GetGroupsHDF5( BRW::HDF5.File, g::String ) -> GroupsN::Vector{String}
        Extract the groups form a BRW open file.
"""
function GetGroupsHDF5( BRW::HDF5.File, g::String )
    GroupsN = [ ];
    try
        GroupsN = string.( g, "/", keys( BRW[ g ] ) );
    catch e
    end
    return GroupsN
end



"""
    GetAttrHDF5( BRW::HDF5.File, g::String ) -> AttrN::Vector{String}
        Extract the attributes form a BRW open file.
        using HDF5
"""
function GetAttrHDF5( BRW::HDF5.File, g::String )
    AttrN = [ ];
    aux = attributes( BRW[ g ] );
    try
        AttrN = string.( g, "/", keys( aux ) );
    catch e
    end
    return AttrN
end



"""
    HDF5Content( BRW::HDF5.File ) -> AllGroups::Vector{Any}
        Generates a list with the entire content of an HDF5 file.
        using GetGroupsHDF5, GetAttrHDF5
"""
function HDF5Content( BRW::HDF5.File )
    Groups = keys( BRW );
    AllGroups = [ ];
    AllAtributes = keys( attributes( BRW ) );
    while !isempty( Groups )
        GROUPS = [ ];
        ATTR = [ ];
        for g in Groups
            if typeof( BRW[ g ] ) == HDF5.Dataset
                push!( AllGroups, g )
            else
                push!( GROUPS, GetGroupsHDF5( BRW, g ) );
                AllAtributes = vcat( AllAtributes, GetAttrHDF5( BRW, g ) );
            end
        end
        Groups = vcat( GROUPS... );
        push!( AllGroups, Groups );
    end
    AllGroups = unique( vcat( AllGroups... ) );
    AllAtributes = unique( AllAtributes );
    return AllGroups, AllAtributes
end



"""
    ExtractRawDataset( BRW::HDF5.File, AllGroups::Vector{Any} ) -> Raw::String, NoRaw::String
        Detects which is the largest dataset and asigns it to Raw data.
"""
function ExtractRawDataset( BRW::HDF5.File, AllGroups::Vector{Any} )
    Types = Vector{ String }( undef, length( AllGroups ) );
    for g = 1:length( AllGroups )
        Types[ g ] = string( typeof( BRW[ AllGroups[ g ] ] ) );
    end
    AllDataSets = AllGroups[ Types .== "HDF5.Dataset" ];
    aux = zeros( Int, length( AllDataSets ) );
    for i = 1:length( AllDataSets )
        aux[ i ] = length( BRW[ AllDataSets[ i ] ] );
    end
    Raw = AllDataSets[ aux .== maximum( aux ) ][ 1 ];
    NoRaw = AllDataSets[ aux .!= maximum( aux ) ];
    aux = aux[ aux .!= maximum( aux ) ];
    NoRaw = NoRaw[ aux .!= 0 ];
    return Raw, NoRaw
end



"""
    ExtractValues( BRW::HDF5.File,  AllAtributes::Vector{String}, NoRaw::Vector{Any} ) -> D::Dict{Any, Any}
        Extracts the values from the BRW file, on Float or Int format if posible.
        using HDF5
"""
function ExtractValues( BRW::HDF5.File,  AllAtributes::Vector{String}, NoRaw::Vector{Any} )
    D = Dict( ); e = [ ];
    for g in NoRaw
        try
            D[ g ] = Float64.( read( BRW[ g ] ) );
        catch e
            D[ g ] = read( BRW[ g ] );
        end
    end
    for g in keys( D )
        if length( D[ g ] ) .== 1
            D[ g ] = D[ g ][ 1 ];
        end
        try
            D[ g ] = Int64( D[ g ] );
        catch e
        end
    end
    for g in AllAtributes
        aux00 = basename( g ); aux01 = dirname( g );
        if isempty( aux01 )
            D[ g ] = read_attribute( BRW, aux00 );
        else
            D[ g ] = read_attribute( BRW[ aux01 ], aux00 );
        end
    end
    return D
end



"""
    ExpDate2Str( Variables::Dict ) -> Variables::Dict
        Extracting the date of the BRW creation
        using Dates
"""
function ExpDate2Str( Variables::Dict )
    X = Variables[ "ExperimentDateTime" ];
    Dt = split( X, ":" );
    Dt[ end ] = string( round( Int, parse( Float64, replace(
        Dt[ end ], r"[A-Z]" => "" ) ) ) );
    newDt = String( "" );
    for i in Dt
        newDt = string( newDt, ":", i );
    end
    newDt = newDt[ 2:end ];
    X = Dates.DateTime( newDt );
    Variables[ "ExperimentDateTime" ] = string( X );
    T = Dates.format( X, RFC1123Format );
    println( "Creation Date: ", T )
    return Variables
end



"""
    ExpSett2Dict( Variables::Dict ) -> Variables::Dict
        Extracting the contents of the ExperimentSettings dictionary
"""
function ExpSett2Dict( Variables::Dict )
    ExperimentSettings = Variables[ "ExperimentSettings" ][ 1 ];
    t = split( ExperimentSettings,"\r\n" );
    t = replace.( t, "  " => "", "{" => "", "}" => "", '"' => "" );
    x = [ ];
    for i = 1:length( t )
        if !isempty( collect( eachmatch( r"[a-z]", t[ i ] ) ) )
            push!( x, true );
        else
            push!( x, false );
        end
    end
    t = t[ Bool.( x ) ]; t = split.( t, ": " );
    D = Dict( );
    for i in t
        if !( i[ 2 ] == "" )
            aux = i[ 2 ];
            try
                aux = replace( i[ 2 ], "," => " ", "[" => "", "[]" => "","]" => "", " " => "" )
            catch e
            end
            if ( aux != "" ) && ( aux != " " )
                aux = aux;
                try
                    aux = parse( Float64, aux );
                catch
                    aux = replace( aux, " " => "" );
                end
                D[ i[ 1 ] ] = aux;
            end
        end
    end
    delete!( Variables, "ExperimentSettings" );
    Variables = merge( Variables, D );
    return Variables
end



"""
    CleanDictionary( D::Dict{Any, Any} ) -> D::Dict{Any, Any}
        Clean the entry dictionary form empty or null values.
"""
function CleanDictionary( D::Dict{Any, Any} )
    X = String.( keys( D ) )[ values( D ) .== "null" ];
    for x in X
        delete!( D, x );
    end
    X = [ ];
    for k in keys( D )
        try
            if isempty( D[ k ] )
                push!( X, k );
            end
        catch e
        end
    end
    for x in X
        delete!( D, x );
    end
    return D
end



"""
    GetVarsHDF5( FILEBRW::String ) -> Variables::Dict, FILEPATHS::String, FILEVARS::String
        Extracts all contents from a HDF5 file of all versions, except the Raw dataset, which only shows the string with the location
        using HDF5, Dates, JLD
        using HDF5Content, ExtractRawDataset, ExtractValues, ExpSett2Dict, ExpDate2Str, CleanDictionary
"""
function GetVarsHDF5( FILEBRW::String )
    BRW = h5open( FILEBRW, "r" );
    AllGroups, AllAtributes = HDF5Content( BRW );
    Raw, NoRaw = ExtractRawDataset( BRW, AllGroups );
    Variables = ExtractValues( BRW,  AllAtributes, NoRaw );
    dset = BRW[ Raw ];
    BRWSIZEGB =  ( stat( FILEBRW ).size ) / ( 1024 * 1024 * 1024 );
    DataSetSize = ( sizeof( dset[ 1 ] ) * size( dset )[ 1 ] ) / ( 1024 * 1024 * 1024 );
    Variables[ "Raw" ] = Raw;
    Variables[ "BRWNAME" ] = BRW.filename;
    Variables[ "BRWSIZEGB" ] = BRWSIZEGB;
    Variables[ "DSETSIZEGB" ] = DataSetSize;
    NewVars = Dict( ); K = keys( Variables );
    for k in K; NewVars[ basename( k ) ] = Variables[ k ]; end; Variables = NewVars;
    if ( "ExperimentSettings" in keys( Variables ) )
        Variables = ExpSett2Dict( Variables );
        Variables = ExpDate2Str( Variables );
    end
    Variables = CleanDictionary( Variables );
    if isempty( findall( occursin.( "Chs", collect( keys( Variables ) ) ) ) )
        Variables[ "nChs" ] = 4096;
    else
        Variables[ "nChs" ] = length( Variables[ "Chs" ] );
    end
    PATHBRWs = dirname( FILEBRW );
    PATHMAIN = joinpath( dirname( PATHBRWs ), split( basename( FILEBRW ), "." )[ 1 ] );
    PATHINFO = joinpath( PATHMAIN, "Info" ); mkpath( PATHINFO );
    FILEVARS = joinpath( PATHINFO, "Variables.jld2" );
    save( FILEVARS, "Variables", Variables );
    BRWNAME = basename( Variables[ "BRWNAME" ] );
    println( "You are now working on the new main path: ", PATHMAIN );
    println( "With the file: ")
    print( BRWNAME, " : ", Variables[ "Description" ] );
    println( " HDF5 file size: $BRWSIZEGB GB" );
    close( BRW )
    cd( PATHMAIN )
    return Variables
end



"""
    ChunkSizeSpace( Variables::Dict, limupper::Real ) -> σ::Int64
        Estabish the number of segmets to cut form each brw file considering the upper limit in GB size limupper for arrays in Float16 format
"""
function optimal_file_size(Variables::Dict, limupper::Real)
    NRecFrames = Variables["NRecFrames"]
    SamplingRate = Variables["SamplingRate"]
    upper_tolerance = limupper + (limupper * 0.15)
    σ = Int(floor(Variables["DSETSIZEGB"] / limupper))
    if σ == 0
        σ = Int(ceil(Variables["NRecFrames"] / (Variables["SamplingRate"] * 2)))
        finalsize = Variables["DSETSIZEGB"] / σ
        println("No optimal segment size found for limupper set, setting default segment duration to 2 seconds")
        
        return finalsize, σ
    end
    finalsize = Variables["DSETSIZEGB"] / σ

    if finalsize > limupper && finalsize < upper_tolerance && NRecFrames % σ != 0
        finalsize = Variables["DSETSIZEGB"] / σ
    elseif finalsize > upper_tolerance
        while finalsize > upper_tolerance && NRecFrames % σ != 0
            σ += 1
            finalsize = Variables["DSETSIZEGB"] / σ
            if finalsize <= upper_tolerance 
                break
            end
        end
        if finalsize > upper_tolerance
            σ = Int(ceil(Variables["NRecFrames"] / (Variables["SamplingRate"] * 2)))
            finalsize = Variables["DSETSIZEGB"] / σ
            println("No optimal segment size found for limupper set, setting default segment duration to 2 seconds")
        end
    end

    return finalsize, σ
end


function ChunkSizeSpace(Variables::Dict, limupper::Real)
    finalsize, σ = optimal_file_size(Variables, limupper);
    finaltime = (Variables["NRecFrames"] / σ) / Variables["SamplingRate"]  # sec
    fs = round(finalsize, digits=3)
    ft = round(finaltime, digits=3)
    println("$σ segments of $fs GB and $ft seconds each")
    return σ
end

function ChunkSizeSpaceGraph(Variables::Dict, limupper::Real)
    finalsize, σ = optimal_file_size(Variables, limupper);
    finaltime = (Variables["NRecFrames"] / σ) / Variables["SamplingRate"]  # sec
    fs = round(finalsize, digits=3)
    ft = round(finaltime, digits=3)
    println("$σ segments of $fs GB and $ft seconds each")
    return σ, ft, fs
end


"""
    OneSegment( Variables::Dict, n::Int64, nSegments::Int ) -> BIN::::Matrix{Float64}
        Takes just one segment of the BRW file.
        using HDF5
"""
function OneSegment( Variables::Dict, n::Int64, nSegments::Int )
    nChs = Variables[ "nChs" ];
    NRecFrames = Variables[ "NRecFrames" ];
    binlenght =  Int(floor(NRecFrames / nSegments));
    Raw = h5open( Variables[ "BRWNAME" ], "r" )[ Variables[ "Raw" ] ];
    BIN = Array{ UInt16 }( undef, nChs, binlenght );
    for frame = ( ( ( n - 1 ) * binlenght ) + 1 ): binlenght * n
        BIN[ :,
            ( frame - ( binlenght*( n - 1 ) ) ) ] .=
                Raw[ ( ( ( frame - 1 ) * nChs ) + 1 ): nChs * frame ];
    end
    close( Raw )
    return BIN
end



"""
    Digital2Analogue( Variables::Dict, DigitalValue::Matrix{UInt16} ) -> BIN::Matrix{Float64}
        Conversion of raw data extracted from the brw file to voltage values (μV) for Matrix format acording to the equation
        Voltage = ( RawData + ADCCountsToMV ) * MVOffset
"""
function Digital2Analogue( Variables::Dict, DigitalValue::Matrix{UInt16} )
    SignalInversion = Variables[ "SignalInversion" ];
    MinVolt = Variables[ "MinVolt" ];
    MaxVolt = Variables[ "MaxVolt" ];
    BitDepth = Variables[ "BitDepth" ];
    MVOffset = SignalInversion * MinVolt;
    ADCCountsToMV = ( SignalInversion * ( MaxVolt - MinVolt ) ) / ( 2^BitDepth );
    BIN = @. MVOffset + ( DigitalValue * ADCCountsToMV );
    return BIN
end



"""
    UniqueCount( data::Array ) -> Count::Vec{Int64}
        Counts the number of unique values for each row of an array
"""
function UniqueCount( data::Array )
    X, Y = size( data );
    Count = Array{ Int64 }( undef, X );
    [ Count[ x ] = length( unique( round.( data[ x, : ], digits = 2 ) ) ) for x in 1:X ];
    return Count
end



"""
    Neighbours( C::Int64, d::Int64 ) -> A::Array{ Int64 }, v::Vector{ Int64 }
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
    aux = [ ( x - d ),( x + d ), ( y - d ), ( y + d ) ]
    aux[ aux .< 1 ] .= 1; aux[ aux .> 64 ] .= 64;
    A = Layout[ aux[ 3 ]:aux[ 4 ], aux[ 1 ]:aux[ 2 ] ];
    v = vec( A )[ vec( A ) .!= center ];
    return A, sort( v )
end



"""
    Desaturation( Constants::Dict, BIN::Matrix ) -> BIN::Matrix{Float64}, Discarded::Dict
        Detects voltage values above the maximum limit and below the minimum limit permited.
        Saturations above the permited percetage, all channel is reconstructed with the 8-neighborhood mean, if is below percetage, is filled with random values from the same channel
        using StatsBase
        using Neighbors
"""
function Desaturation( Constants::Dict, BIN::Matrix )
    maxvolt = Constants[ "maxvolt" ];
    minvolt = Constants[ "minvolt" ];
    LimSaturacion = Constants[ "LimSaturacion" ];
    minchannels = Constants[ "minchannels" ];
    maxradius = Constants[ "maxradius" ];
    nChs = size( BIN, 2 );
    channels = collect( 1:nChs );
    Discarded = Dict( );
    aux = findall( BIN .>= maxvolt .|| BIN .<= minvolt );
    SatChannels = getindex.( aux, [ 1 ] );
    SatFrames = getindex.( aux, [ 2 ] );
    aux01 = unique( SatChannels );
    AllFrames = [ ];
    AllChannels = [ ];
    for ch in aux01
        push!( AllChannels, ch );
        push!( AllFrames, SatFrames[ SatChannels .== ch ] );
    end
    AllFrames = AllFrames[ sortperm( AllChannels ) ];
    AllChannels = sort( AllChannels );
    ValidChs = setdiff( channels, AllChannels );
    SatLevel = length.( AllFrames ) / size( BIN, 2 );
    Empties = AllChannels[ SatLevel .>= LimSaturacion ];
    if isempty( Discarded )
        Discarded[ "Channels" ] = AllChannels;
        Discarded[ "Frames" ] = AllFrames;
        Discarded[ "Empties" ] = Empties;
    end
    if !isempty( Empties )
        for emptie in Empties
            radius = 1;
            _, neighs = Neighbours( emptie, radius );
            ValidNeighbors = [ ];
            ValidNeighbors = intersect( neighs, ValidChs );
            A = ( length( ValidNeighbors ) .>= minchannels );
            while !A && radius <= maxradius
                radius = radius + 1;
                _, neighs = Neighbours( emptie, radius );
                ValidNeighbors = intersect( neighs, ValidChs );
                A = ( length( ValidNeighbors ) .>= minchannels );
            end
            BIN[ emptie, : ] = mean( BIN[ ValidNeighbors, : ], dims = 1 );
        end
    end
    aux = AllChannels .∉ [ Empties ];
    SatFrames = AllFrames[ aux ];
    SatChannels = AllChannels[ aux ];
    for i = 1:length( SatChannels );
        satch = SatChannels[ i ];
        satfrs = SatFrames[ i ];
        Nsatfrs = length( satfrs );
        ValidFrs = setdiff( 1:size( BIN, 2 ), satfrs );
        BIN[ satch, satfrs ] = sample( BIN[ satch, ValidFrs ], Nsatfrs );
    end
    return BIN, Discarded
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #



# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
end # MODULE_STEP_01
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #


