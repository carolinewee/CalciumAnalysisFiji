//converts OIBs, LSMs, CZIs etc to Tiff Files

setBatchMode(true);

source_dir = getDirectory("Source Directory");
target_dir = getDirectory("Target Directory");

list = getFileList(source_dir);
list = Array.sort(list);

 for (i=0; i<list.length; i++) {
 	Image = source_dir + list[i];
 	run("Bio-Formats Importer", "open='"+ Image +"' color_mode=Default view=Hyperstack stack_order=XYCZT");
 	saveAs("tiff", target_dir + "/" + list[i] + ".tiff");
 	close();
 }