// Alex Zwetsloot 10.02.18 v.1
// Where be the data landlubber? Put ye the foldername in 'ere
var input = "/Users/alex/Downloads/inputfolder"
// Where puts the output me 'earty? Put ye the foldername in 'ere
var output = "/Users/alex/Downloads/inputfolder/montages"

// All images will be scaled identically! You must choose here what the min/max they should be scaled as.
// You can work this out just by playing with the histogram and using those values.
var min_c1 = 110
var max_c1 = 1000
var min_c2 = 150
var max_c2 = 1700
 
function autoMontage(filename) {
	print("Working on "+filename);
	run("Bio-Formats Importer", "open="+input+"/"+filename + " autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	//open(input+"/"+filename);
	var name = getTitle();
	run("Split Channels");
	selectWindow("C1-"+name);
	setMinAndMax(min_c1, max_c1);
	selectWindow("C2-"+name);
	setMinAndMax(min_c2, max_c2);
	run("Merge Channels...", "c1=C1-"+name+" c2=C2-"+name+" create keep");
	run("Stack to RGB");
	close(name);
	selectWindow(name + " (RGB)");
	run("Scale Bar...", "width=20 height=10 font=26 color=White background=None location=[Lower Right] bold");
	run("Images to Stack", "name=Stack title=[] use");
	run("Make Montage...", "columns=3 rows=1 scale=1 border=10");
	saveAs("Jpeg",output+"/Montage_"+name+".jpg");
	print("Saving output to: "+output+"/Montage_"+name+".jpg");
	// Close all images.
	while (nImages>0) { 
    	selectImage(nImages); 
        close(); 
    } 

}

print("Starting auto-montage");
setBatchMode(true);
list = getFileList(input);
for (i = 0; i < list.length -1; i++) {
	if (!endsWith(list[i], "/"))) {
		print("Processing " + list[i]);
        autoMontage(list[i]);
	}
}
setBatchMode(false);
