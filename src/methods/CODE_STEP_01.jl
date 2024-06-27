# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
PATHFUNCTIONS = ".";
push!( LOAD_PATH, PATHFUNCTIONS );
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
import MODULE_STEP_01.GetVarsHDF5
import MODULE_STEP_01.FindContent
import MODULE_STEP_01.ChunkSizeSpace
import MODULE_STEP_01.ChunkSizeSpaceGraph
import MODULE_STEP_01.OneSegment
import MODULE_STEP_01.Digital2Analogue
import MODULE_STEP_01.UniqueCount
import MODULE_STEP_01.Desaturation
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
import MODULE_GRAPHS.stdΔV
import MODULE_GRAPHS.RemoveInfs
import MODULE_GRAPHS.Zplot
import MODULE_GRAPHS.convgauss
import MODULE_GRAPHS.RemoveSaturationExtrema
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
using JLD2
using Plots
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
Constants = Dict(
    "maxvolt"       => 2500, # μV
    "minvolt"       => -2500, # μV
    # how much of the channel can we tolerate being saturated before patching it all
    "LimSaturacion" => 0.2, # [ 0, 1 ]
    "minchannels"   => 6, # needed valid channels on the neighborhood
    "maxradius"     => 4 # maximus radius for the searching neighborhood ( 1 -> 8 )
    );

# Constants to graph
ΔT = 250; # ms for ΔV
sigma = 3; # For the Gaussian convolution

# Variables
#FILEBRW = "C:/Users/murph/OneDrive/Escritorio/BRW's/BRW/0-20s.brw"
#limUpperChunk = 0.25
#QtitleGraph = "# V values conv"
#Qcolor = :Spectral
#Qcbar = false

println("Iniciando...");
println("FILEBRW Julia: ", FILEBRW);
println("LimUpperChunk Julia: ", limUpperChunk);
println("QtitleGraph Julia: ", QtitleGraph);
println("Qcolor Julia: ", Qcolor);
println("Qcbar Julia: ", Qcbar);

Variables = GetVarsHDF5( FILEBRW );
FILEVARIABLES = FindContent( "Variables.jld2", FILEBRW );
PATHINFO = dirname( FILEVARIABLES );
PATHMAIN = pwd( );
PATHVOLTAGE = joinpath( PATHMAIN, "Voltage" ); mkpath( PATHVOLTAGE );
FILESTEP0Ws = joinpath( PATHINFO, "STEP_01_WS.jld2" );
PATHDISCARDED = joinpath( PATHINFO, "Discarded" ); mkpath( PATHDISCARDED );
PATHVOLTAGEDESAT = joinpath( dirname( PATHINFO ), "Desaturation" ); mkpath( PATHVOLTAGEDESAT );
PATHFIGURES = joinpath( PATHMAIN, "Figures" ); mkpath( PATHFIGURES );

nChs = Variables[ "nChs" ];
N = ChunkSizeSpace( Variables, limUpperChunk );
nFrs = Int( floor(Variables[ "NRecFrames" ] / N ));
n0s = length( string( N ) );

_, ft, fs = ChunkSizeSpaceGraph( Variables, limUpperChunk );
QtitleGraphSecs = string("$ft seconds");

#@time for n = 1 : N;
#    BINRAW = OneSegment( Variables, n, N );
#    BINRAW = Digital2Analogue( Variables, BINRAW );
#    BINNAME = joinpath( PATHVOLTAGE, string( "BIN", lpad( n, n0s, "0" ), ".jld2" ) ); 
#    NΔV = stdΔV( Variables, BINRAW, ΔT );
#    RowCount = UniqueCount( BINRAW );
#    h = copy( RowCount ); hg = convgauss( sigma, h );
#    data = vec( RemoveInfs( abs.( log.( hg ) ) ) );
#    #P = Zplot( data, "W", Qcolor ); PP = title!( QtitleGraph );
#    #PF = plot( P, layout = ( 1, 1 ), wsize = ( 800, 800 ), cbar = Qcbar);
#    P = Zplot( data, "W", Qcolor ); title!( QtitleGraph );
#    PF = plot( P, wsize = ( 800, 800 ), cbar = Qcbar, legendtitle = QtitleGraphSecs, legendposition = :bottom );
#    FIGNAME = joinpath( PATHFIGURES, string( "BIN", lpad( n, n0s, "0" ), ".svg" ));
#    FIGNAME = joinpath( PATHFIGURES, FIGNAME );
#    savefig( PF, FIGNAME );
#
#    println("$n listo de $N");
#end