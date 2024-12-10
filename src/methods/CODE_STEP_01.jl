"""
    Collection of functions for analysis of BRW (HDF5) files generated with the BrainWave program from the company 3Brain.
    Laboratory 19 of the CINVESTAV in charge of Dr. Rafael Gutierrez Aguilar.
    Work developed mainly by Isabel Romero-Maldonado (2020 - )
    isabelrm.biofisica@gmail.com
    https://github.com/LBitn
    https://github.com/LBitn/Hippocampus-HDMEA-CSDA.git
"""
push!( LOAD_PATH, dirname(@__FILE__) );

using AllSTEPs

using JLD2
using StatsBase
using Plots
using Measures

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
# Variables for Qt GUI
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
#PATHINFO = "C:/Users/murph/OneDrive/Escritorio/BRW's/version03/Info"
#cm_ = :vik;
#limSat = 0.2;
#THR_EMP = 4000; # Max: 4125
#Δt = 50;

println("Iniciando...");
println("Path selected: ", PATHINFO );
println("cm_ Julia: ", cm_);
println("limSat Julia: ", limSat);
println("THR_EMP Julia: ", THR_EMP);
println("Δt Julia: ", Δt);

PATHMAIN = dirname( PATHINFO );
PATHSTEP00 = joinpath( PATHMAIN, "STEP00" );
PATHSTEP01 = replace( PATHSTEP00, "STEP00" => "STEP01" ); mkpath( PATHSTEP01 );
PATHFIGURES = joinpath( PATHMAIN, "Figures" );
PATHFIGURES_STEP01 = joinpath( PATHFIGURES, "STEP01" ); mkpath( PATHFIGURES_STEP01 );
PATHFIGURES_GENERAL = joinpath( PATHFIGURES, "GENERAL" ); mkpath( PATHFIGURES_GENERAL );

FILESTEP01 = joinpath( PATHMAIN, "Info", "STEP01.jld2" );
FILEVARIABLES = joinpath( PATHINFO, "Variables.jld2" );
FILESTEP00 = joinpath( PATHMAIN, "Info", "STEP00.jld2" );
FILEPARAMETERS = joinpath( PATHINFO, "Parameters.jld2" );
FILESVOLTAGE = SearchDir( PATHSTEP00, ".jld2" );

Variables = LoadDict( FILEVARIABLES );
step00 = LoadDict( FILESTEP00 );
Parameters = LoadDict( FILEPARAMETERS );

N = Parameters[ "N" ];

cte = 100; # μV of range that are assigned to the maximum voltage to set the threshold for saturation.
MaxVolt = Variables[ "MaxVolt" ]; # Maximum possible voltage registered by the equipment
THR_SES = abs( MaxVolt - cte ); # Threshold to be considered for setting saturation
plotfonts = Plots.font( pointsize = 10, family = "sans-serif" ); # Font type for all the plots

minchan = 8; # minimum channels for channel reconstruction
maxrad = 4; # maximum ratio of neighborhood, for channel reconstruction
maxIt = 5; # maximum number of iterations, for channel reconstruction

n0s = length( string( N ) ); # Suffix for STEP01-Figures-name
l = @layout [ a{ 0.48w, 1.0h } b{ 0.52w, 1.0h } ]; # Layout for save STEP01-Figures

Empties = step00[ "Empties" ];

## All for Raw Bin Behavior
#aux = vcat( sum.( step00[ "Cardinality" ], dims = 1 )... );
#W = zscore( aux );
#fc = :royalblue3;
#t = "\n" ^ 1 * "Raw Bin Behavior";
#xl = "n bin";
#yl = "zscore of Σ( Cardinality )";
#plotfonts = Plots.font( pointsize = 10, family = "sans-serif" );
#
#P00 = BarPlot( W, fc, t, xl, yl );
#P00 = plot( 
#    P00, 
#    plotfont = plotfonts,
#    xticks =  ( 0:5:N )
#);
#
#FILEFIGURE_RawBinBehavior = joinpath( PATHFIGURES_GENERAL,"RawBinBehavior" );
#Plots.png( P00, FILEFIGURE_RawBinBehavior );
#Plots.svg( P00, FILEFIGURE_RawBinBehavior );

Cardinality = Array{ Any }( undef, N ); fill!( Cardinality, [ ] );
VoltageShiftDeviation = Array{ Any }( undef, N ); fill!( VoltageShiftDeviation, [ ] );
Sats = Array{ Any }( undef, N ); fill!( Sats, [ ] );
Repaired = Array{ Any }( undef, N ); fill!( Repaired, [ ] );

#channel = 1;
#n1 = 8200;
#n_overlap1 = 8100;
#Channel_Spectrogram( BINPATCH, 3249, 8200, 8100 )

#@time for n in 1:N
#    local BINNAME = joinpath( PATHSTEP00, string( "BIN", lpad( n, n0s, "0" ), ".jld2" ) );
#    BINPATCH = Float64.( LoadDict( BINNAME ) ); # Load the n-segment in Float64
#    local nChs, nFrs = size( BINPATCH );
#    BINPATCH[ Empties, : ] .= 0;
#    
#    local SatChs, SatFrs = SupThr( BINPATCH, THR_SES );
#    local aux = SatChs .∉ [ Empties ];
#    SatChs = SatChs[ aux ];
#    SatFrs = SatFrs[ aux ];
#
#    Chs4Repair = [ ];
#    Frs4Repair = [ ];
#    
#    for ch in 1:length( SatChs )
#        sch = SatChs[ ch ];
#        sfr = SatFrs[ ch ];
#        g = ReduceArrayDistance( sfr, 1 );
#        for G in g
#            push!( Chs4Repair, sch );
#            push!( Frs4Repair, G );
#        end
#    end
#
#    OriginalSaturations = Dict(
#        "Chs" => Chs4Repair,
#        "Frs" => Frs4Repair
#    );
#    
#    Sats[ n ] = OriginalSaturations; 
#    
#    FRS = OriginalSaturations[ "Frs" ];
#    CHS = OriginalSaturations[ "Chs" ];
#
#    for s = 1:length( Chs4Repair )
#        ch = Chs4Repair[ s ];
#        fr = Frs4Repair[ s ];
#        NoFrs = sort( vcat( FRS[ CHS .∈ [ ch ] ] ...) );
#        nsf = length( fr );
#        ValidFrames = setdiff( 1:nFrs, NoFrs );
#		
#		if isempty( ValidFrames )
#            println("Empty channel: $ch");
#            continue
#        end
#		
#        fictional_segment = sample( ValidFrames, nsf );
#        local channel = BINPATCH[ ch, : ];
#        fictional_segment = channel[ fictional_segment ];
#        BINPATCH[ ch, fr ] = fictional_segment;
#    end
#
#    Repaired[ n ] = Dict( 
#        "Chs" => Chs4Repair,
#        "Frs" => Frs4Repair
#    );
#    
#    for emptie in Empties
#        rad = 1
#        _, neigh = Neighbours( emptie, rad );
#        while length( neigh ) <= minchan && rad <= maxrad
#            rad = rad + 1;
#            _, neigh = Neighbours( emptie, rad );
#        end
#        neighs = sort( sample( neigh, minchan, replace = false ) );
#        BINNEIGHS = BINPATCH[ neighs, : ];
#        fictional_channel = ReconstructChannels( BINNEIGHS, maxIt );
#        BINPATCH[ emptie, : ] = fictional_channel;
#    end
#    
#    jldsave( replace( BINNAME, "STEP00" => "STEP01" ); Data = Float16.( BINPATCH ) );
#    
#    CAR = [ ];
#    VSD = [ ];
#    CAR = UniqueCount( BINPATCH );
#    VSD = STDΔV( Variables, BINPATCH, Δt );
#    SecondEvaluation = Dict(
#        "Cardinality"            => CAR,
#        "VoltageShiftDeviation"  => VSD,
#    );
#    
#    Cardinality[ n ] = SecondEvaluation[ "Cardinality" ];
#    VoltageShiftDeviation[ n ] = SecondEvaluation[ "VoltageShiftDeviation" ];
#    
#    aux = PatchEmpties( CAR, Empties );
#    P0 = plot( );
#    P0 = Zplot( zscore( aux ), cm_, false, "\n" ^ 2 * "Cardinality of the Voltage" );
#    aux = PatchEmpties( VSD, Empties );
#    P1 = plot( );
#    P1 = Zplot( zscore( aux ), cm_, false, "\n" ^ 2 * "Voltage Shift Deviation" );
#    local P = plot( );
#    P = plot( P0, P1, layout = l, wsize = ( 800, 400 ) );
#    title = plot( );
#    title = plot( title = "\n" ^ 2 * "Second evaluation, Repaired Data", grid = false, showaxis = false, bottom_margin = -50Plots.px );
#    F = plot( );
#    F = plot( title, P, layout = @layout( [ A{ 0.1h }; B{ 0.9h } ] ), wsize = ( 800, 500 ), titlefont = plotfonts, );
#    local FILEFIGURE_STEP01 = joinpath( PATHFIGURES_STEP01, string( "BIN", lpad( n, n0s, "0" ) ) );
#    Plots.png( F, FILEFIGURE_STEP01 );
#
#    println("$n listo de $N");
#end