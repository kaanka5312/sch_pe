# Install magick package if not already installed
# install.packages("magick")

library(magick)

# Read multiple PNG files (change the pattern to your needs)
files <- list(
  "D:/SoCAT/ElifOzgeSCH/SCHdata/analysis/secondlevel/Cov_HC_oneSampleT_0030/hc_uncorr.png",
  "D:/SoCAT/ElifOzgeSCH/SCHdata/analysis/secondlevel/Cov_SZ_oneSampleT_0030/cov_sz.png",
  "D:/SoCAT/ElifOzgeSCH/SCHdata/analysis/secondlevel/Cov_twoSampleT_0030/sz_hc_cov.png"
)

# Read all images
imgs <- lapply(files, image_read)

imgs <- lapply(imgs, image_resize, "x800")

# Create a black rectangle
black_rect <- image_blank(width = 1126, height = 100, color = "black")

imgs <- lapply(imgs, function(im) image_append(c(black_rect,im),stack = TRUE))

# Labels for each image
labels <- c("A", "B", "C")  # same length as imgs

# Add labels (top-left corner)
imgs_labeled <- mapply(function(img, label) {
  image_annotate(img,
                 text = label,
                 size = 80,                 # font size
                 gravity = "NorthWest",     # top-left
                 location = "+0+0",       # offset from top-left in pixels
                 color = "white",
                 boxcolor = "black")        # optional background box
}, imgs, labels, SIMPLIFY = FALSE)

# Labels for each image
headers <- c("HC", "SZ", "SZ > HC")  # same length as imgs

imgs_headed <- mapply(function(img, label) {
  image_annotate(img,
                 text = label,
                 size = 80,                 # font size
                 gravity = "North",     # top-left
                 location = "+0-0",       # offset from top-left in pixels
                 color = "white",
                 boxcolor = "black")        # optional background box
}, imgs_labeled, headers, SIMPLIFY = FALSE)


merged <- image_append(image_join(imgs_headed), stack = FALSE)

# Save to disk
image_write(merged, 
            path = "C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/results/figures/brain_plot.png", 
            format = "png")
