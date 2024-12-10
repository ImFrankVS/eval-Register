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

# For STEP00
using JLD2
using StatsBase
using HDF5

# For Ploting and Spectro
using DSP
using Measures
using Plots

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
# Variables for Qt GUI
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
#FILEBRW = "C:/Users/murph/OneDrive/Escritorio/BRW's/BRW/version03.brw";
#MaxGB = 0.2;
#cm_ = :vik;
#limSat = 0.2;
#THR_EMP = 4000;
#Δt = 50;
#n1 = 8200;
#n_overlap1 = 8100;
#minSegments = 3;

println("Iniciando...");
println("FILEBRW Julia: ", FILEBRW);
println("MaxGB Julia: ", MaxGB);
println("cm_ Julia: ", cm_);
println("limSat Julia: ", limSat);
println("THR_EMP Julia: ", THR_EMP);
println("Δt Julia: ", Δt);
println("n1 Julia: ", n1);
println("n_overlap1 Julia: ", n_overlap1);
println("minSegments: ", minSegments);

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
# Obtaining the metadata of the selected file
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
Variables = GetVarsHDF5( FILEBRW );

N, ft, fs, flagQtUI = GetChunkSize( Variables, MaxGB, minSegments);
n0s = length( string( N ) );

# STEP00-General Dirs
PATHMAIN = joinpath( dirname( dirname( FILEBRW ) ), split( basename( FILEBRW ), "." )[ 1 ] );
PATHINFO = joinpath( PATHMAIN, "Info" );
PATHSTEP00 = joinpath( PATHMAIN, "STEP00" ); mkpath( PATHSTEP00 );

# STEP00-Figure Dirs
PATHFIGURES = joinpath( PATHMAIN, "Figures" );
PATHFIGURES_STEP00 = joinpath( PATHFIGURES, "STEP00" ); mkpath( PATHFIGURES_STEP00 );
PATHSPECTROGRAMS = joinpath( PATHFIGURES, "Spectrograms" ); mkpath( PATHSPECTROGRAMS );

# STEP00-General .jld2
FILESTEP00 = joinpath( PATHINFO, "STEP00.jld2" );
FILEPARAMETERS = joinpath( PATHINFO, "Parameters.jld2" );

# Pre-allocating arrays to store the results for all N segments
Cardinality = Array{ Any }( undef, N ); fill!( Cardinality, [ ] );
VoltageShiftDeviation = Array{ Any }( undef, N ); fill!( VoltageShiftDeviation, [ ] );
Empties = Array{ Any }( undef, N ); fill!( Empties, [ ] );

# Some parameters for initialize the segments arrays
nChs = Variables[ "nChs" ];
nfrs = floor( Int, ( Variables[ "NRecFrames" ] / N ) );
RAW  = h5open( Variables[ "BRWNAME" ], "r" )[ Variables[ "RAW" ] ];

#@time for n = 1:N
#    BINRAW = OneSegment( RAW, Variables, n, N );
#    BINRAW = Digital2Analogue( Variables, BINRAW );
#    local nChs, nfrs = size( BINRAW );
#    
#    BINNAME = joinpath( PATHSTEP00, string( "BIN", lpad( n, n0s, "0" ), ".jld2" ) );
#    jldsave( BINNAME; Data = Float16.( BINRAW ) );
#
#    SatChs, SatFrs = SupInfThr( BINRAW, THR_EMP );
#    PerSat = zeros( nChs );
#    PerSat[ SatChs ] .= round.( length.( SatFrs ) ./ nfrs, digits = 2 );
#    empties = findall( PerSat .>= limSat );
#
#    Cardinality[ n ] = UniqueCount( BINRAW );
#    data = zscore( PatchEmpties( Cardinality[ n ], empties ) );
#    P = Zplot( data, cm_ );
#    PF = plot( P, wsize = ( 64, 64 ), cbar = Qcbar, margins = -2mm );
#    FIGNAME = joinpath( PATHFIGURES_STEP00, string( "BIN", lpad( n, n0s, "0" ), "_" ) );
#    Plots.png( PF, FIGNAME );
#    
#    VoltageShiftDeviation[ n ] = STDΔV( Variables, BINRAW, Δt );
#    data = zscore( PatchEmpties( VoltageShiftDeviation[ n ], empties ) );
#    P = Zplot( data, cm_ );
#    PF = plot( P, wsize = ( 64, 64 ), cbar = Qcbar, margins = -2mm );
#    FIGNAME = joinpath( PATHFIGURES_STEP00, string( "BIN", lpad( n, n0s, "0" ), "_std" ) );
#    Plots.png( PF, FIGNAME );
#    
#    Empties[ n ] = empties;
#    println("$n listo de $N");
#end
#
#close( RAW )
#
## Combine the empty channels across all segments and ensure uniqueness
#Empties = sort( unique( vcat( Empties... ) ) );
#
#step00 = Dict(
#    "Cardinality"           => Cardinality,
#    "VoltageShiftDeviation" => VoltageShiftDeviation,
#    "Empties"               => Empties,
#    );
#jldsave( FILESTEP00; Data = step00 ); # Save the step00 results into a .jld2 file
#
#Parameters = Dict(
#    "MaxGB"   => MaxGB,    # Maximum GB limit used during the process
#    "limSat"  => limSat,   # Saturation limit for detecting empty channels
#    "THR_EMP" => THR_EMP,  # Threshold for detecting saturated channels
#    "Δt"      => Δt,       # Time interval for voltage shift deviation
#    "N"       => N,        # Total number of segments processed
#    "cm_"     => cm_       # Color for STEP01 Plots
#);
#jldsave( FILEPARAMETERS; Data = Parameters );  # Save the parameters into a .jld2 file








#data = vec( RemoveInfs( abs.( log.( convgauss( 3 , Cardinality[ n ] ) ) ) ) );
#data = vec( RemoveInfs( abs.( log.( convgauss( 3 , VoltageShiftDeviation[ n ] ) ) ) ) );