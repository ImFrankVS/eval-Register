"""
    Collection of functions for analysis of BRW (HDF5) files generated with the BrainWave program from the company 3Brain.
    Laboratory 19 of the CINVESTAV in charge of Dr. Rafael Gutierrez Aguilar.
    Work developed mainly by Isabel Romero-Maldonado (2020 - )
    isabelrm.biofisica@gmail.com
    https://github.com/LBitn
    https://github.com/LBitn/Hippocampus-HDMEA-CSDA.git
"""
BINNAME = joinpath( PATHSTEP00, string( "BIN", lpad( n, n0s, "0" ), ".jld2" ) );
BINRAW = Float64.( LoadDict( BINNAME ) ); # Load the n-segment in Float64
nChs, nFrs = size( BINRAW );
BINPATCH = deepcopy( BINRAW );
BINPATCH[ Empties, : ] .= 0; # Discarded channels are flattened to 0

SatChs, SatFrs = SupThr( BINRAW, THR_SES );
# Remove empty channels from the list to properlly evaluate saturations ( not needed )
aux = SatChs .∉ [ Empties ];
SatChs = SatChs[ aux ];
SatFrs = SatFrs[ aux ];

Chs4Repair = [ ];
Frs4Repair = [ ];

for ch in 1:length( SatChs )
    sch = SatChs[ ch ];
    sfr = SatFrs[ ch ];
    g = ReduceArrayDistance( sfr, 1 );
    for G in g
        push!( Chs4Repair, sch );
        push!( Frs4Repair, G );
    end
end

OriginalSaturations = Dict(
    "Chs" => Chs4Repair,
    "Frs" => Frs4Repair
);

Sats[ n ] = OriginalSaturations;

FRS = OriginalSaturations[ "Frs" ];
CHS = OriginalSaturations[ "Chs" ];

for s = 1:length( Chs4Repair )
    ch = Chs4Repair[ s ];
    fr = Frs4Repair[ s ];
    NoFrs = sort( vcat( FRS[ CHS .∈ [ ch ] ] ...) );
    nsf = length( fr );
    ValidFrames = setdiff( 1:nFrs, NoFrs );
    fictional_segment = sample( ValidFrames, nsf );
    local channel = BINPATCH[ ch, : ];
    fictional_segment = channel[ fictional_segment ];
    BINPATCH[ ch, fr ] = fictional_segment;
end

Repaired[ n ] = Dict( 
    "Chs" => Chs4Repair,
    "Frs" => Frs4Repair
);

for emptie in Empties
    rad = 1
    _, neigh = Neighbours( emptie, rad );
    while length( neigh ) <= minchan && rad <= maxrad
        rad = rad + 1;
        _, neigh = Neighbours( emptie, rad );
    end
    neighs = sort( sample( neigh, minchan, replace = false ) );
    BINNEIGHS = BINPATCH[ neighs, : ];
    fictional_channel = ReconstructChannels( BINNEIGHS, maxIt );
    BINPATCH[ emptie, : ] = fictional_channel;
end

jldsave( replace( BINNAME, "STEP00" => "STEP01" ); Data = Float16.( BINPATCH ) );

CAR = [ ];
VSD = [ ];
CAR = UniqueCount( BINPATCH );
VSD = STDΔV( Variables, BINPATCH, Δt );
SecondEvaluation = Dict(
    "Cardinality"            => CAR,
    "VoltageShiftDeviation"  => VSD,
);

Cardinality[ n ] = SecondEvaluation[ "Cardinality" ];
VoltageShiftDeviation[ n ] = SecondEvaluation[ "VoltageShiftDeviation" ];

# Cardinality
P0 = plot( );
data = zscore( PatchEmpties( CAR, Empties ) );
P0 = Zplot( data, cm_, false, "\n" ^ 2 * "Cardinality of the Voltage" );

# GUI Figures code....
PP0 = plot();
PP0 = Zplot( data, cm_, true ); #   -> PP = Zplot( data, cm_, true, "", clims = c::Real = 0);
PPF = plot( PP0, wsize = ( 64, 64 ), cbar = false, margins = -2mm );
FIGNAME = joinpath( PATHFIGURES_STEP01, string( "BIN", lpad( n, n0s, "0" ), "_" ) );
Plots.png( PPF, FIGNAME );

# VoltageShiftDeviation
P1 = plot( );
data = zscore( PatchEmpties( VSD, Empties ) );
P1 = Zplot( data, cm_, false, "\n" ^ 2 * "Voltage Shift Deviation" );

# GUI Figures code....
PP1 = plot();
PP1 = Zplot( data, cm_, true ); #   -> PP = Zplot( data, cm_, true, "", clims = c::Real = 0);
PPF = plot( PP1, wsize = ( 64, 64 ), cbar = false, margins = -2mm );
FIGNAME = joinpath( PATHFIGURES_STEP01, string( "BIN", lpad( n, n0s, "0" ), "_std" ) );
Plots.png( PPF, FIGNAME );

# Final Figure
P = plot( );
P = plot( P0, P1, layout = l, wsize = ( 800, 400 ) );
title = plot( );
title = plot( title = "\n" ^ 2 * "Second evaluation, Repaired Data", grid = false, showaxis = false, bottom_margin = -50Plots.px );

F = plot( );
F = plot( title, P, layout = @layout( [ A{ 0.1h }; B{ 0.9h } ] ), wsize = ( 800, 500 ), titlefont = plotfonts, );

FILEFIGURE_STEP01 = joinpath( PATHFIGURES_STEP01, string( "BIN", lpad( n, n0s, "0" ) ) );
Plots.png( F, FILEFIGURE_STEP01 );

println("$n listo de $N");

# aux code...
# sizeBytes = Base.summarysize( BINPATCH ) / 1_048_576
# sizeBytes = Base.summarysize( BINRAW ) / 1_048_576

