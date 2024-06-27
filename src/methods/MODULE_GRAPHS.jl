"""
    Collection of functions for analysis of BRW (HDF5) files generated with the BrainWave program from the company 3Brain.
    Laboratory 19 of the CINVESTAV in charge of Dr. Rafael Gutierrez Aguilar.
    Work developed mainly by Isabel Romero-Maldonado (2020 - )
    isabelrm.biofisica@gmail.com
    https://github.com/LBitn
"""
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
module MODULE_GRAPHS
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
using Plots
using StatsBase
using Statistics
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
export ms2Frs
export stdΔV
export RemoveInfs
export Zplot
export Z0
export ZW
export convgauss
export Neighbors
export RemoveSaturationExtrema
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    ms2Frs( Variables::Dict, time::Real ) -> x::Float64
        For conversion from ms to an integer number of frames
"""
function ms2Frs( Variables::Dict, time::Real )
    SamplingRate = Variables[ "SamplingRate" ];
    if time != 0; x = ceil( Int, ( time * SamplingRate ) / 1000 ); else; x = 1; end
    return x
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    stdΔV( Variables::Dict, BIN::Matrix{Float64}, ΔT::Real ) -> STD::Vector{Float64}
        ΔT en msec
        using Statistics
        using ms2Frs
"""
function stdΔV( Variables::Dict, BIN::Matrix{Float64}, ΔT::Real )
    ΔT = ms2Frs( Variables, ΔT );
    STD = vec( std( ( BIN - circshift( BIN, ( 0, ΔT )  ) ), dims = 2 ) );
    return STD
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
function RemoveInfs( data::VecOrMat )
    m = minimum( data[ data .!= -Inf ] );
    M = maximum( data[ data .!= Inf ] );
    data[ data .== -Inf ] .= m;
    data[ data .== Inf ] .= M;
    return data
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    Zplot( Z::VecOrMat, which::String, cm = :greys ) -> F::Plot
        which = "0", entry vector of numbers for a Back and White plot
        using Z0, ZW
        using Plots
"""
function Zplot( Z::VecOrMat, which::String, cm = :greys, nChs = 4096 )
    if which == "0"
        Z = Z0( Z, nChs );
    elseif which == "W"
        Z = ZW( Z );
    end
    F = heatmap( Z, aspect_ratio = 1, c = cm, axis = ( [ ], false ), wsize = ( 400, 400 ) );
    if which == "0"
        plot!( F, cbar  = :none )
    end
    return F
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    Z0( X::VecOrMat, nChs::Int64 ) -> Z::Matrix{Int64}
        using Plots
"""
function Z0( X::VecOrMat, nChs::Int64 )
    X = Int.( vec( X ) );
    Z = zeros( Int, nChs );
    n = Int( sqrt( nChs ) );
    Z[ X ] .= Z[ X ] .+ 1;
    Z = reverse( reshape( Z, n, n )', dims = 1 );
    return Int.( Z )
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    ZW( X::VecOrMat ) -> Z::Matrix{typeof(X)}
        using Plots
"""
function ZW( X::VecOrMat )
    X = vec( X );
    n = Int( sqrt( length( X ) ) );
    Z = reverse( reshape( X, n, n )', dims = 1 );
    return Z
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
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
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    Neighbors( C::Int64, d::Int64 ) -> A::Array{ Int64 }, v::Vector{ Int64 }
        A = Array( ( d*2 ) + 1, ( d * 2 ) + 1 ),
        v = vec( 2*( ( d * 2 ) + 1 ) - 1 );
        The d-neighborhood is calculated from the channel ( C ) as a center
        A = array where C is the center and is in chip order
        v = same neighboring channels as A but in vector form and without C ( 8 channels for d = 1 )
"""
function Neighbors( center::Int64, d::Int64 )
    Layout = reverse( reshape( collect( 1:4096 ), 64, 64 )', dims = 1 );
    x = findall( Layout .== center )[ ][ 2 ];
    y = findall( Layout .== center )[ ][ 1 ];
    aux = [ ( x - d ),( x + d ), ( y - d ), ( y + d ) ]
    aux[ aux .< 1 ] .= 1; aux[ aux .> 64 ] .= 64;
    A = Layout[ aux[ 3 ]:aux[ 4 ], aux[ 1 ]:aux[ 2 ] ];
    v = vec( A )[ vec( A ) .!= center ];
    return A, v
end
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
"""
    RemoveSaturationExtrema( Constants::Dict, BIN::Matrix ) -> BIN::Matrix{Float64}, Discarded::Dict{Any,Any}
        Detects voltage values above the maximum limit and below the minimum limit permited.
        Saturations above the permited percetage, all channel is reconstructed with the 8-neighborhood mean, if is below percetage, is filled with random values from the same channel
        using StatsBase
        using Neighbors
"""
function RemoveSaturationExtrema( Constants::Dict, BIN::Matrix )
    maxvolt = Constants[ "maxvolt" ];
    minvolt = Constants[ "minvolt" ];
    limite_saturacion = Constants[ "LimSaturacion" ];
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
    Empties = AllChannels[ SatLevel .>= limite_saturacion ];
    if isempty( Discarded )
        Discarded[ "Channels" ] = AllChannels;
        Discarded[ "Frames" ] = AllFrames;
        Discarded[ "Empties" ] = Empties;
    end
    if !isempty( Empties )
        for emptie in Empties
            radius = 1;
            _, neighs = Neighbors( emptie, radius );
            ValidNeighbors = [ ];
            ValidNeighbors = intersect( neighs, ValidChs );
            A = ( length( ValidNeighbors ) .>= minchannels );
            while !A && radius <= maxradius
                radius = radius + 1;
                _, neighs = Neighbors( emptie, radius );
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
end # MODULE_GRAPHS
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
