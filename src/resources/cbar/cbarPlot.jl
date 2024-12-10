using Plots
using Measures
using FileIO

function cbarPlot(cm_::Symbol)
    colorData = reshape(range(0, stop=1, length=100), :, 1);
    cbarPlot = heatmap(colorData, color=cm_, legend=false, ticks=:none, wsize = ( 25, 500 ), margins = -2mm);

    Plots.png(cbarPlot, string(cm_));
	
	# Rotate 90 degrees to the right
	namePath = string(cm_);
	img = FileIO.load("./$namePath.png");
	imgRot = reverse(permutedims(img, (2, 1)), dims=2);
	
	FileIO.save("./$namePath.png", imgRot);
end

colorSchemes = [ :blues, :bluesreds, :grays, :greens, :heat, :reds, :redsblues, :algae, :amp, :matter, :inferno, :vik ];

for color in colorSchemes
	cbarPlot(color);
end