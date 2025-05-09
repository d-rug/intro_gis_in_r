# Intro to GIS in R
An introduction to doing Geographic Information Science in R. This workshop
is (roughly speaking) the R version of [Next Steps in QGIS][ns_qgis]. We will 
be covering:

  - The tools R has to to geospatial work
  - Importing (reading) data into R
  - Basic plotting
  - (re)Projecting data
  - Filtering data
  - Regular and Spatial Joins
  - Geoprocessing Tools
  - Raster Math
  - Exporting (writing) data

This workshop assumes you have some experience with R. If you are new to R or
would like to brush up on your skills, the [DataLab R Basics Reader][rbasics] is
a great place to start. It also assumes you are familiar with GIS concepts like
rasters, vectors, coordinate reference systems etc, which is covered in 
[Intro to Desktop GIS with QGIS][intro_qgis].

[ns_qgis]: https://drive.google.com/file/d/1JviOWp_8x_SXv46nJCVlef1s9t9jqcUw/view
[rbasics]: https://ucdavisdatalab.github.io/workshop_r_basics/
[intro_qgis]: https://ucdavisdatalab.github.io/Intro-to-Desktop-GIS-with-QGIS/

## Setup

### Before the Workshop

For this workshop you will need to download R, which you can do on [CRAN][cran]
(the Comprehensive R Archive Network). It will also be a lot easier if you
download RStudio, which you can do [here][posit]. As a note, RStudio is free and
if you are being asked for payment, you are trying to download the wrong
version.

[cran]: https://cran.r-project.org/
[posit]: https://posit.co/download/rstudio-desktop/

### During the Workshop

The first thing we need to do is set up our workspace. We are going to do this
with RStudio, but you can accomplish the same thing using the R GUI. 

  1. Go to File -> New Project, or click on the Project button in the upper right
  hand corner of the window and select "New Project"
  2. Select "New Directory".
  3. Project Setup for "New Directory"
      a. Select "New Project" for Project Type
      b. Give your directory a name (ex. 'intro_gis_in_r')
      c. Browse and select where you want to create your new directory
      d. Click "Create Project".
      e. Navigate to the Files tab in RStudio and click "New Folder", and name
    that folder "data".
      f. Navigate inside that folder and create another folder named "raw".


Next we need to download the data. The data for this workshop is stored on Box
and can be downloaded using this [link][box]. Once you have downloaded the data,
unzip the folder and move it into the `data/raw` folder in your project
directory.

[box]: https://ucdavis.app.box.com/s/cnlz6ejmje4qgf7z80h7ygbwydc65kkm

#### Packages
R is not natively a GIS program. However, enterprising individuals and groups
have written extensions to R, called packages, that contain the data types and
tools to do most GIS tasks, some better than others. R is very good at things
like geoprocessing and analysis. In particular, it excels at automating doing
the same process over and over. However, its visualization tools are sub-par
compared to a desktop GIS application like QGIS.

Like in QGIS, the tools for raster and vector GIS are (largely) separate. 
The following is a summary of some of the most commonly used spatial 
packages in R.

  - `sf`: vector GIS
  - `terra`: raster GIS, with limited vector functionality
  - `geodata`: downloads raster and vector data, based on `terra`
  - `tigris`: downloads census polygons, based on `sf`
  - `tidycensus`: downloads census data, based on `sf`
  - `rnaturalearth`: downloads global administrative (ex. country) boundaries
      for visualization, `sf` and `terra` support
  - `osrm`
  - `tmap`
  - `tmaptools`

For this workshop we will be using `sf` and `terra`. We can install them by
running the following code in the R Console.

```
install.packages('sf', 'terra')
```

Now you are ready to start coding! All of the code can be found in
`R/intro_gis.R`. Additionally Elise will save the code she writes during the
workshop as `R/intro_gis_live.R` and upload it after the workshop.

> [!IMPORTANT]
>
> Originally, the primary tool for working with raster data was a package 
> called `raster` and the primary tools for working with vector data were contained in the
> packages `sp`, `rgdal`, `rgeos`, and `maptools`. Those packages have been
> entirely superseded now by `terra` and `sf` respectively. Some of them are
> still on CRAN for legacy reasons, but you SHOULD NOT USE THEM. If you find a
> tutorial online that uses them, ignore it.

## Vector GIS in R

The `sf` package is the primary package for vector GIS. To load `sf` into R.

```
library('sf')
```

### Importing Data with `sf`

We can import spatial vector data into R using the function `st_read()`. The
`st_read()` function will import just about any type of explicitly spatial
data. To get a list of all of the file types it will read, run `st_drivers`.
This will list all of the different file types `sf` can read in, and will also 
tell you if `sf` can write those file types.

```
streets <- st_read('data/raw/streetCenterlines.shp')
streets
```

If we want to check to make sure the data looks how we expect, we can plot it
using `st_geometry()` and `plot()`.

```
streets_geom <- st_geometry(streets)
plot(streets_geom)
```

In addition to shapefiles, `st_read()` also imports GeoJSONs, which is the file
type of our seismic hazard zone data set.

```
hz <- st_read('data/raw/seismic_hazard_zones_san_francisco.geojson')
```

To visualize a data set using a column to provide color to polygons, select
that column when plotting:

```
hz_title <- 'Seismic Hazard Zones by Hazard Type in San Francisco'
plot(hz[,'hazard'], key.pos=1, main=hz_title)
```


#### Importing Tabular Data

We can also read in non-spatial data (like CSVs) into R, using a variety of 
functions. One of the most popular is `read.csv()`.

```
trees_df <- read.csv('data/raw/Street_Tree_Map.csv')
```

This creates a data.frame. To convert a data.frame to a `sf` object, we use the
`st_as_sf()` function. I don't remember the inputs for `st_as_sf()`, so I can
use the `?st_as_sf` to ask R.

```
trees <- st_as_sf(x=trees_df,
                  coords=c('Longitude', 'Latitude'),
                  crs=4326)
```

Huh, looks like there are some `NAs` in the lat/lon points. Let's remove those.

```
trees_df <- trees_df[!is.na(trees_df$Longitude), ]
trees <- st_as_sf(x=trees_df,
                  coords=c('Longitude', 'Latitude'),
                  crs=4326)
```

Much better! Now lets see what the trees look like plotted.

```
trees_geom <- st_geometry(trees)
plot(trees_geom)
```

This is a problem! But we will need a few more tools in our tool kit before we
can fix it.

### Projecting Data in `sf`
 
Just like in desktop GIS, in R we need data layers to share a CRS in order to
use them together. We can project `sf` objects into a new CRS using
`st_transform()`. Since we are working in California, we will use the California
Albers projection, which has a EPSG code of 3310. We can check to see what CRS
our data layers have using `st_crs()`.

```
st_crs(streets)$input
st_crs(hz)$input
st_crs(trees)$input

```

It looks like our seismic hazard data is already in California Albers, but our
street trees need to be projected.

```
trees_ca <- st_transform(trees, crs=3310)
streets_ca <- st_transform(streets, crs=3310)
```

### Geoprocessing



## Raster GIS in R
