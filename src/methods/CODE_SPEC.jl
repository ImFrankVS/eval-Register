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

# For Ploting and Spectro
using Plots

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
# Working with jldsave
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
#PATHINFO = "C:/Users/murph/OneDrive/Escritorio/BRW's/version03/Info"

println("Iniciando...");
println("Path selected: ", PATHINFO );

PATHMAIN = dirname( PATHINFO );
PATHSTEP00 = joinpath( PATHMAIN, "STEP00" );

PATHSTEP01 = replace( PATHSTEP00, "STEP00" => "STEP01" ); mkpath( PATHSTEP01 );
PATHFIGURES = joinpath( PATHMAIN, "Figures" );
PATHSPECTROGRAMS = joinpath( PATHFIGURES, "Spectrograms" );
PATHFIGURES_STEP01 = joinpath( PATHFIGURES, "STEP01" ); mkpath( PATHFIGURES_STEP01 );
PATHFIGURES_GENERAL = joinpath( PATHFIGURES, "GENERAL" ); mkpath( PATHFIGURES_GENERAL );

FILEVARIABLES = joinpath( PATHINFO, "Variables.jld2" );
FILESTEP00 = joinpath( PATHMAIN, "Info", "STEP00.jld2" );
FILEPARAMETERS = joinpath( PATHINFO, "Parameters.jld2" );

Variables = LoadDict( FILEVARIABLES );
step00 = LoadDict( FILESTEP00 );
Parameters = LoadDict( FILEPARAMETERS );

N = Parameters[ "N" ];
n0s = length( string( N ) );

#segment = 1;
#channelSpectro = 3249;
#n1 = 8200;
#n_overlap1 = 8100;

#BINNAME = joinpath( PATHSTEP00, string( "BIN", lpad( segment, n0s, "0" ), ".jld2" ) );
#BINPATCH = Float64.( LoadDict( BINNAME ) );
#p = Channel_SpectrogramTest(BINPATCH, channelSpectro, 8200, 8100)
#filename_string = joinpath( PATHSPECTROGRAMS, "BIN_$(lpad(segment, n0s, "0"))_Channel_$channelSpectro");
#Plots.png(p, filename_string);