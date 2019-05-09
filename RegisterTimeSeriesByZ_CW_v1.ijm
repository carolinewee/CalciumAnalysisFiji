// CAROLINE WEE 2019
// Useful for aligning calcium imaging data over time.
// Registers single-channel or dual time series images stored in individual
// folders and saves/renames them in output folder.
// Will be prompted to specify both source and target directories.
// Each image in each folder is assumed to be a z stack from a time series.
// Option of translation or rigidbody.
// Using TurboReg macro plugin https://imagej.net/TurboReg
// If Bioformat importer required -- either modify code accordingly (replace
// line 50 with line 52) or first run ConvertImagestoTiff_CW_v1.ijm
// Once running, the only way I know to kill it is to close imageJ!

// THESE PARAMETERS NEED TO BE SET FOR EACH EXPERIMENT
nchannels = 1; // need to specify if only 1 channel or 2
refslice = 1; // reference slice

// "translation" or "rigidbody". Currently the landmarks are set based on image
// dimensions, and may have to be tweaked depending on nature of image
type = "translation";

setBatchMode(true);

if (nchannels == 1) {
  source_dir = getDirectory("Source Directory");
} else if (nchannels == 2) {
  source_dir = getDirectory("Source Directory_greenchannel");
  source_dir2 = getDirectory("Source Directory_redchannel");
}

target_dir = getDirectory("Target Directory");

for (channelnum = 1; channelnum <= nchannels; channelnum++) {

  channel = channelnum - 1; // 0 or 1 (channel 0 is green, channel 1 is red)

  // If there is a red channel, after registering green channel, also
  // register=red.

  if (channelnum == 1) {
    list = getFileList(source_dir);
  } else if (channelnum == 2) {
    list = getFileList(source_dir2);
  }

  list = Array.sort(list);

  for (i = 0; i < list.length; i++) {
    j = i + 1;

    if (channelnum == 1) {
      Image = source_dir + list[i];
    } else if (channelnum == 2) {
      Image = source_dir2 + list[i];
    }

    open(Image);

    // If bioformat importer needed, use next line instead of `open(Image)`:
    // run("Bio-Formats Importer", "open='"+ Image +"' color_mode=Default view=Hyperstack stack_order=XYCZT");

    rename("Image");

    // Get the dimensions of the current image
    Stack.getDimensions(width, height, channels, slices, frames)

    // To get target image (first slice):
    run("Make Substack...", "slices=" + refslice);
    selectWindow("Substack (" + refslice + ")");
    rename("target");

    // Adapted from forum.imagej.net
    for (k = 1; k <= slices; k++) { //for each slice
      selectWindow("Image");
      setSlice(k);
      run("Duplicate...", "title=currentFrame");

      // Registration using TurboReg

      if (type == "rigidbody") {
        run("TurboReg ", "-align "
            // source
            + "-window currentFrame "
            // no cropping. Need to change if image size is different!
            + "0 0 " + width + " " + height + " "
            // target
            + "-window target "
            // no cropping. Need to change if image size is different!
            + "0 0 " + width + " " + height + " "
            // requires 3 landmarks
            + "-rigidBody "
            + width / 3 + " " + height / 3 * 2 + " " + width / 3 + " " + height
            / 3 * 2 + " " // rigidbody landmark
            + width / 3 * 2 + " " + height / 3 * 2 + " " + width / 3 * 2 + " "
            + height / 3 * 2 + " " // rigidbody angle landmark
            + width / 2 + " " + height / 2 + " " + width / 2 + " " + height / 2
            + " " // rigidbody angle landmarks
            + "-showOutput");

      } else if (type == "translation") {
        run("TurboReg ", "-align "
            // source
            + "-window currentFrame "
            // no cropping. Need to change if image size is different!
            + "0 0 " + width + " " + height + " "
            // target
            + "-window target "
            // no cropping. Need to change if image size is different!
            + "0 0 " + width + " " + height + " "
            // requires 1 landmark
            + "-translation "
            + width / 2 + " " + height / 2 + " " + width / 2 + " " + height / 2
            + " " // translation landmark
            + "-showOutput");
      }

      selectWindow("Output");
      // To get first frame. 2nd frame is the mask which we don't want.
      run("Duplicate...", "title=registered");

      // Concatenate each registered image into a stack.
      if (k == 1) {
        run("Duplicate...", "title=" + "registeredstack");
        close("registered");
      } else {
        run("Concatenate...",
            "title=" + "registeredstack" + " image1=" + "registeredstack"
            + " image2=registered");
      }

      close("Output");
      close("currentFrame");
    }

    selectWindow("registeredstack");

    // Output of TurboReg is 32-bit float.
    // Save registered stack as a tiff.
    saveAs("tiff",
        target_dir + "/" + "channel" + channel + "-z" + j + "registered.tiff");
    close();
    run("Close All");
  }
}

setBatchMode(false);