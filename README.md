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
vectors, rasters, coordinate reference systems etc, which is covered in 
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

The first thing we need to do is set up our workspace. This is similar to 
creating to creating a project in QGIS. We are going to do this
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
  - `osrm`: interface for using the OpenStreetMap based Routing Service
  - `tmap`: better mapping in R
  - `tmaptools`: tools for doing better mapping in R, as well as a number of 
  other things

For this workshop we will be using `sf`, `rnaturalearth`, `terra`, and `geodata`
geospatial packages. We will also be using the `dplyr` data manipulation
package. We can install them by running the following code in the R Console.

```
install.packages('sf', 'rnaturalearth', 'terra', 'geodata', 'dplyr')
```

Now you are ready to start coding! All of the code can be found in
`R/intro_gis.R`. Additionally Elise will save the code she writes during the
workshop as `R/intro_gis_live.R` and upload it after the workshop.

> [!WARNING]
>
> Originally, the primary tool for working with raster data was a package 
> called `raster` and the primary tools for working with vector data were 
> contained in the packages `sp`, `rgdal`, `rgeos`, and `maptools`. Those
> packages have been entirely superseded now by `terra` and `sf` respectively.
> Some of them are still on CRAN for legacy reasons, but you SHOULD NOT USE
> THEM. If you find a tutorial online that uses them, ignore it.

### Workshop Objective

This section of the workshop covers roughly the same skills as the Next Steps in
QGIS workshop. 

San Francisco is quite prone to earthquakes. It also has many large trees that
could do quite a bit of damage to you if they fell over. The goal of this
workshop is to identify areas to avoid in San Francisco during an earthquake to
prevent having a large tree fall on your head. We will do this by combining
street tree data with information on seismic hazard zones, and plotting the
resulting information against the backdrop of San Francisco roadways.

## GIS in R with `terra`

The `terra` package is the primary GIS package in R for working with rasters.
It has a lot of vector funcitonality as well. To load `terra` into R.

```
library('terra')
library('rnaturalearth')
```

### Importing Data with `terra`

We can import spatial vector data into R using the function `vect()`. The
`vect()` function will import just about any type of explicitly spatial vector
data, creating a `spatVector` object. To get a list of all of the file types it
will read, run `gdal(drivers=TRUE)`. This will list all of the different file
types `terra` can read in, and will also tell you if `terra` can write those
file types.

```
streets <- vect('data/raw/streetCenterlines.shp')
streets
```

If we want to check to make sure the data looks how we expect, we can plot it
using `plot()`.

```
plot(streets)
```

Our streets data does give us a general idea of what San Francisco looks like,
but for visualizations it would be good to have an outline. Thankfully we have
shoreline data as well.

```
shore <- vect('data/raw/Shoreline.shp')
plot(shore, col='skyblue', main='San Francisco Shoreline', border='darkblue')
```

In addition to shapefiles, `vect()` also imports GeoJSONs, which is the file
type of our seismic hazard zone data set.

```
hz <- vect('data/raw/seismic_hazard_zones_san_francisco.geojson')
```

To visualize a data set using a column to provide color to polygons, provide the
name of that column as the second argument when plotting:

```
hz_title <- 'Seismic Hazard Zones by Hazard Type in San Francisco'
plot(hz, 'hazard', main=hz_title)
```


#### Importing Tabular Data

We can also read in non-spatial data (like CSVs) into R, using a variety of 
functions. One of the most popular is `read.csv()`.

```
trees_df <- read.csv('data/raw/Street_Tree_Map.csv')
head(trees_df)
dim(trees_df)
```


### Data Conversion

Sometimes we have data in one form, but we want to convert it to a different
form. Our shoreline data is a polygon, but if we plot that, it will cover up
anything we plot under it. For data we want to use as an outline, it is easier
to store it using the (multi)linestring geometry instead of the polygon
geometry. In `terra` we can convert between spatial data types using `as.*()`, 
functions. To convert our polygon object to a line object, we use `as.lines()`.

```
shoreline = as.lines(shore)
```


We can also convert non-spatial data, like our trees data set, to spatial data.
To convert a`data.frame` to a `sf` object, we use the `vect()` function. I
don't remember the inputs for using `vect()` to convert a `data.frame` to a 
`spatVector`, so I can use the `?vect` to ask R.

```
trees <- vect(trees_df, geom=c('Longitude', 'Latitude'), crs='EPSG:4326')
```

Much better! Now we've got our tree data in the correct form, let's plot it.

```
plot(trees)
```

Hmmm...Something doesn't look right. Lets add the outline of the US to see 
if we can figure out what is going on...

```
usa <- ne_countries(country='united states of america', returnclass='sv')
plot(usa)
plot(trees, add=TRUE)
```

Yikes, we've got trees in the ocean! This is definitely a problem. There are
several ways to get rid of points are not within your area of study, but they
all require that your data all has the same coordinate reference system (CRS).



### Projecting Data in `terra`
 
Just like in desktop GIS, in R we need data layers to share a CRS in order to
use them together. We can project `spatVectors` into a new CRS using
`project()`. Since we are working in California, we will use the California
Albers projection, which has a EPSG code of 3310. We can check to see what CRS
our data layers have using `crs()`.

```
crs(streets, describe=TRUE)
crs(hz, describe=TRUE)
crs(trees, describe=TRUE)
crs(shoreline, describe=TRUE)

```

It looks like our seismic hazard data is already in California Albers, but our
street, shore, tree data need to be projected. Since `hz` is alredy in
California Albers, we can use that to tell `terra` how to project the data.

```
trees_ca <- project(trees, hz)
streets_ca <- project(streets, hz)
shore_ca <- project(shore, hz)
shoreline_ca <- project(shoreline, hz)

```

Much better! Now to get rid of those pesky ocean trees.


### Data Filtering

Huh, looks like there are some `NAs` in the our tree data locations. Let's
remove those. With `terra` objects, we can filter observations much like
we would a data.frame.

```
trees_ca <- trees_ca[!is.na(trees_ca$XCoord), ]
dim(trees_ca)

```

Probably the easiest way to remove outlandish data, is to clip/crop the data
using another layer that has the extent you want. In our case we can use the 
seismic hazard zones, since those are the only areas we care about. First,
we create a `spatExtent` object using `ext()`, and then we use the `crop` 
function to remove extraneous points.

```
hz_ext <- ext(hz)
trees_ca <- crop(trees_ca, hz_ext)
```


If we plot both layers together, we can see that we've successfully gotten rid
of our problematic trees. 

```
plot(hz, col='lightblue', main=hz_title)
plot(trees_ca, col='darkgreen', pch='.', add=TRUE)
```

We also have some extraneous islands of the west coast of San Francisco in our
shoreline data set that would be nice to remove, so we can crop `shoreline_ca`
as well.

```
shore_ca <- crop(shore_ca, hz_ext)
shoreline_ca <- crop(shoreline_ca, hz_ext)

```

There is a problem with our shoreline data, which is that includes the southern
border of San Francisco, which is not, in fact, a shoreline. We can use the
`erase()` function to remove the section of the shoreline layer, but first we
need to create a polygon that overlaps with that part our data. The easiest way
to do this is by creating a `spatExtent` using `ext()` and then converting that
to a `spatVector` using `as.polygons()`.

```
south_ext <- ext(-122.6, -122.39346, 37.6, 37.71)
south <- as.polygons(south_ext, crs=crs(streets))
south_ca <- project(south, hz)
```

Now that we have our polygon, we can use it to erase!

```
better_shoreline <- erase(shoreline_ca, south_ca)
plot(better_shoreline)

```

That looks much more like the actual San Francisco shoreline.


#### A Function Interlude

Since R is not primarily a GIS program, it does not provide us with automatic
visual updates every time we create or modify a data layer. We have to do that
ourselves using `plot()` (among other functions). Typing out two plot commands
with all the arguments gets tedious, so let's create a function that will
do it for us.

```
plot_trees <- function(geom_top, geom_bottom, poly_color='lightblue', ...) {
  plot_title <- 'Street Trees in San Francisco'
  plot(geom_bottom, col=poly_color, main=plot_title,  axes=FALSE) 
  
  plot(geom_top, add=TRUE, ...)
  
}

```

Now instead of writing two commands over and over again, we can write one,
simpler, command.

```
plot_trees(trees_ca, hz, col='darkgreen', pch='.')
```

#### Back to filtering!

If we take a look at the seismic hazard data, it actually contains two
different kinds of hazards: liquefaction and landslide. While landslides are 
very dangerous, liquefaction is the primary concern in terms of trees falling
over.

```
unique(hz$hazard)
```

So, lets filter the seismic hazard data set (`hz`) to only include liquefaction
hazard polygons. Our `hz` object is a `data.frame` in addition to being an `sf`
object. This means we can filter it like we would a regular `data.frame`. 

```
hz_liquid <- hz[hz$hazard == 'liquefaction', ]
plot_trees(trees_ca, hz_liquid, col='darkgreen', pch='.')

```

Additionally, we really only need to avoid big trees. Thankfully the street tree
data set includes the tree diameter at breast height (DBH), a standard way of
measuring tree size. Any time we work with a field from a large data set, it is
a good idea to get a sense of what values that field takes on before trying to
do anything with it. Some examples of functions that do this are `summary()` and
`hist()`.

```
summary(trees_ca$DBH)
hist(trees_ca$DBH)
```

Well we definitely need to remove the 39,000 trees with missing DBH values.
Additionally, the largest tree in the world (The Tule Tree) is only 384 inches
in diameter, so let's also assume that diameters greater than 384 are errors and
remove those as well. Finally, it seems prudent to avoid trees with a diameter
of 4ft (or more), so we will filter out trees with DBHs of less than 48in as not
large enough to worry about.

```
is_big <- !is.na(trees_ca$DBH) & trees_ca$DBH<384 & trees_ca$DBH>=48
trees_big <- trees_ca[is_big, ]
plot_trees(trees_big, hz_liquid, col='darkgreen', pch=16, cex=0.5)

```

### Geoprocessing

We still have a lot of the trees in the data set we don't care about,
namely, all the trees that aren't in a liquefaction zone. We can combine
these two data sets using a spatial join. The `intersect()` function
gives us data from where two layers overlap. However, it only includes the 
geometries from the first data layer.

```
trees_hz <- intersect(trees_big, hz_liquid)
names(trees_big)
names(hz_liquid)
names(trees_hz)
trees_hz
```

If typing out `intersect` seems like to much work, we can also use the `*` 
operator.

```
trees_hz <- trees_big * hz_liquid

```


If we plot them, we can see that our new trees data set only contains trees in
the liquefaction hazard zones.

```
plot_trees(trees_hz, hz_liquid, col='darkred', pch=16, cex=0.7)

```

Now it's not enough to know where these large trees are. We would really like to
avoid any area within 200ft of them. Since the unit of measure for California
Albers is meters (see `crs(trees_hz, parse=TRUE)`), we want to avoid anywhere within 62m
of the danger trees. We can create a layer representing this data using
`buffer()`.

```
danger_zones = buffer(trees_hz, width=62)
plot_trees(danger_zones, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)
```

This new data layer contains the information want. However, there are a lot of
overlapping polygons that make it difficult to tell what is going on visually.
We can combine multiple polygons into a single polygon using `aggregate()`.

```
danger_zone = aggregate(danger_zones)
plot_trees(danger_zone, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)
```

We can also combine the liquefaction and landslide zones, since we don't need
information about individual zones.

```
hazard_zone = aggregate(hz, by='hazard')
liquid_zone = hazard_zone[ hazard_zone$hazard == 'liquefaction', ]
plot_trees(danger_zone, liquid_zone, col='red', border='darkred', pch=16, cex=0.7)
```

We are going to need a way to label streets in these areas in liquefaction zones
near trees as dangerous, and we can do that by creating a new field in the
`streets_ca` object.

### Spatial Relations

While `intersect()` is a useful function, it only does one type of spatial
relation: intersection. The `is.related()` and `relate()` functions do all of
them. They also allow us to classify geometries as being related without
removing non-related geometries from our data set. In this case we want to
know which streets (`streets_ca`) intersect our danger zone (`danger_zone`).
We use `is.related()` because there is only one geometry we are comparing our 
street locations to. This creates a TRUE/FALSE vector, which we can use to
create another column in `streets_ca`.


```
in_danger_zone <- is.related(streets_ca, danger_zone, relation='intersects')
```

The options for the `relation` argument have very specific definitions, which
may not align with the colloquial definitions of those words. If you what to
know what the definition of a particular relation is, or if you are trying to
figure out why your spatial join isn't working how you expected it to, the
Wikipedia article on the [DE-9IM model][de9im] provides in depth details on each
of the options.

[de9im]: https://en.wikipedia.org/wiki/DE-9IM

We can now use `in_danger_zone` to create the new field in our `streets_ca` 
`spatVector` using the dollar sign operator ($). This method also works for
creating new columns in data.frames.

```
streets_ca$in_danger <- in_danger_zone

```


Now if we look at `streets_ca`, the values of `in_danger` are TRUE/FALSE, which 
won't make for a very good legend. So we should create a new column we can use
for plotting that is more descriptive.

```
head(streets_ca)
```

We can fill in those missing values with text that indicates these streets are
okay to walk down.

```
streets_ca$status <- ifelse(streets_ca$in_danger, 'Danger!', 'Have a nice walk :)')

```


### Plotting

We've already done some plotting in R using the plot function, but now we
finally have all of the data we need to create a map of all the places we should
avoid during an earthquake if we don't want large tree to fall on our head.

```
danger_title <- 'Street Safety Status Under Seismic Hazards'
plot(streets_ca, 'status', main=danger_title, axes=FALSE)
```

The colors aren't great, so let's specify some better ones. In this case, dark
red and grey seem fairly evocative of what we are trying to communicate

```
plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),  main=danger_title, axes=FALSE)
```

This is good, but it would be nice to know where the shoreline is.

```
#with the shoreline
plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),  main=danger_title, axes=FALSE)
plot(shore_ca, col=NULL, border=NULL, add=TRUE)
plot(better_shoreline, col='darkblue', lwd=2,  add=TRUE)

```

It would be even better if we could visualize the ocean in some way. Thankfully,
`plot()` has an argument called `background` that lets us specify the background
color. However, if we don't want our streets to look under water, we need to 
first plot a white polygon where the San Francisco land mass is.

```
#with a background
plot(shore_ca, col='white', border='white', main=danger_title, axes=FALSE, 
      mar=c(3.1, 3.1, 2.1, 8.1), background='skyblue')
plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),  add=TRUE)
plot(better_shoreline, col='darkblue', lwd=2,  add=TRUE)

```

### Writing Data

If you want to be able to recreate this map, but don't want to have to go
through the data processing steps again, it can be helpful to save the data sets
you created in the process. The function to do this in the `terra` package is
`writeVector()`. This is the equivalent of the "Make Permanent" functionality in
QGIS.

I'm going to save my data sets in a folder called "processed" in my data folder,
so that I know they have gone through data processing. I can create the folder
automatically in R using `dir.create()`.

```
dir.create('data/processed')
```

When using `writeVector()` you have to specify which type of file to create
using the `filetype` argument. To see a list of options for this argument, run

```
gdal(drivers=TRUE)
```

Let's create a geojson file. The filetype for that is 'GeoJSON'. We can save
our street data as a geojson.

```
street_filename <- 'data/processed/street_classification_san_francisco.geojson'
writeVector(streets_ca, street_filename, filetype='GeoJSON', overwrite=TRUE)
```

We can also create a shapefile, which has a driver name of 'ESRI Shapefile'. We
also need to save the shoreline data so let's save that as a shapefile.


```
sl_filename <- 'data/processed/san_francisco_shore_line.shp'
writeVector(better_shoreline, sl_filename, filetype='ESRI Shapefile', overwrite=TRUE)

```

Finally, if we want to recreate the map with the blue background, we will also
need to save the polygon representation of the San Francisco shoreline.

```
shore_filename <- 'data/processed/san_francisco_shore_poly.geojson'
writeVector(shore_ca, shore_filename, filetype='GeoJSON', overwrite=TRUE)

```


## GIS in R with `sf`

The `sf` package is the primary package for vector GIS. To load `sf` into R.

```
library('sf')
library('dplyr')
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

Our streets data does give us a general idea of what San Francisco looks like,
but for visualizations it would be good to have an outline. Thankfully we have
shoreline data as well.

```
shore <- st_read('data/raw/Shoreline.shp')
plot(st_geometry(shore), col='skyblue', main='San Francisco Shoreline', border='darkblue')
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
head(trees_df)
dim(trees_df)
```

### Data Conversion

Sometimes we have data in one form, but we want to convert it to a different
form. Our shoreline data is a polygon, but if we plot that, it will cover up
anything we plot under it. For data we want to use as an outline, it is easier
to store it using the (multi)linestring geometry instead of the polygon
geometry. In `sf` we can convert between spatial data types using `st_cast`, and
specify the geometry type using the `to` argument.

```
shoreline = st_cast(shore, 'MULTILINESTRING')
```


We can also convert non-spatial data, like our trees data set, to spatial data.
To convert a data.frame to a `sf` object, we use the `st_as_sf()` function. I
don't remember the inputs for `st_as_sf()`, so I can use the `?st_as_sf` to ask
R.

```
trees <- st_as_sf(x=trees_df,
                  coords=c('Longitude', 'Latitude'),
                  crs=4326)
```

Huh, looks like there are some `NAs` in the lat/lon points. Let's remove those.

```
trees_df <- filter(trees_df, !is.na(Longitude))
trees <- st_as_sf(x=trees_df,
                  coords=c('Longitude', 'Latitude'),
                  crs=4326)
```

Much better! Now we've got our tree data in the correct form, let's plot it.

```
trees_geom <- st_geometry(trees)
plot(trees_geom)
```

Hmmm...Something doesn't look right. Lets add the outline of the US to see 
if we can figure out what is going on...

```
usa <- rnaturalearth::ne_countries(country='united states of america')
plot(st_geometry(usa))
plot(trees_geom, add=TRUE)
```

Yikes, we've got trees in the ocean! This is definitely a problem. There are
several ways to get rid of points are not within your area of study, but they
all require that your data all has the same coordinate reference system (CRS).


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
st_crs(shoreline)$input

```

It looks like our seismic hazard data is already in California Albers, but our
street, shore, tree data need to be projected.

```
trees_ca <- st_transform(trees, crs=3310)
streets_ca <- st_transform(streets, crs=3310)
shoreline_ca <- st_transform(shoreline, crs=3310)

```

Much better! Now to get rid of those pesky ocean trees.


### Data Filtering

Probably the easiest way to remove outlandish data, is to clip/crop the data
using another layer that has the extent you want. In our case we can use the 
seismic hazard zones, since those are the only areas we care about.

```
trees_ca <- st_crop(trees_ca, hz)
```

> [!NOTE]
>
> The `sf` package will often warn you that "attribute variables are assumed to
> be spatially constant throughout all geometries". This is not an error
> message! It is not even an indication that anything is wrong. All it is
> telling you is that if you have a point, line, or polygon with an attribute,
> hazard = 'landslide' for example, hazard will equal 'landslide' over the 
> entire area of that geometry.


If we plot both layers together, we can see that we've successfully gotten rid
of our problematic trees. 

```
plot(st_geometry(hz), col='lightblue', main=hz_title)
plot(st_geometry(trees_ca), col='darkgreen', pch='.', add=TRUE)
```

We also have some extraneous islands of the west coast of San Francisco in our
shoreline data set that would be nice to remove, so we can crop `shore_ca` as 
well.

```
shore_ca <- st_crop(shore_ca, hz)

```

#### A Function Interlude

Since R is not primarily a GIS program, it does not provide us with automatic
visual updates every time we create or modify a data layer. We have to do that
ourselves using `plot()` (among other functions). Typing out two plot commands
with all the arguments gets tedious, so let's create a function that will
do it for us.

```
plot_trees <- function(geom_top, geom_bottom, poly_color='lightblue', ...) {
  plot_title <- 'Street Trees in San Francisco'
  plot(st_geometry(geom_bottom), col=poly_color, main=plot_title, extent=geom_top)
  
  plot(st_geometry(geom_top), add=TRUE, ...)
  
}

```

Now instead of writing two commands over and over again, we can write one,
simpler, command.

```
plot_trees(trees_ca, hz, col='darkgreen', pch='.')
```

#### Back to filtering!

If we take a look at the seismic hazard data, it actually contains two
different kinds of hazards: liquefaction and landslide. While landslides are 
very dangerous, liquefaction is the primary concern in terms of trees falling
over.

```
unique(hz$hazard)
```

So, lets filter the seismic hazard data set (`hz`) to only include liquefaction
hazard polygons. Our `hz` object is a `data.frame` in addition to being an `sf`
object. This means we can filter it like we would a regular `data.frame`. 

```
hz_liquid <- hz[hz$hazard == 'liquefaction', ]
plot_trees(trees_ca, hz_liquid, col='darkgreen', pch='.')

```

> [!NOTE]
>
> There are many ways of filtering data in R. So far we have seen two of them:
> `filter` from the `dplyr` package, and using `[]` indexing. However, if you
> prefer another method of filtering data.frames, feel free to use that. 


Additionally, we really only need to avoid big trees. Thankfully the street tree
data set includes the tree diameter at breast height (DBH), a standard way of
measuring tree size. Any time we work with a field from a large data set, it is
a good idea to get a sense of what values that field takes on before trying to
do anything with it. Some examples of functions that do this are `summary()` and
`hist()`.

```
summary(trees_ca$DBH)
hist(trees_ca$DBH)
```

Well we definitely need to remove the 39,000 trees with missing DBH values.
Additionally, the largest tree in the world (The Tule Tree) is only 384 inches
in diameter, so let's also assume that diameters greater than 384 are errors and
remove those as well. Finally, it seems prudent to avoid trees with a diameter
of 4ft (or more), so we will filter out trees with DBHs of less than 48in as not
large enough to worry about.

```
is_big <- !is.na(trees_ca$DBH) & trees_ca$DBH<384 & trees_ca$DBH>=48
trees_big <- trees_ca[is_big, ]
plot_trees(trees_big, hz_liquid, col='darkgreen', pch=16, cex=0.5)

```

### Spatial Joins

We still have a lot of the trees in the data set we don't care about,
namely, all the trees that aren't in a liquefaction zone. We can combine
these two data sets using a spatial join. The `st_intersection()` function
gives us data from where two layers overlap. However, it only includes the 
geometries from the first data layer.

```
trees_hz <- st_intersection(trees_big, hz_liquid)
names(trees_big)
names(hz_liquid)
names(trees_hz)
trees_hz
```

If we plot them, we can see that our new trees data set only contains trees in
the liquefaction hazard zones.

```
plot_trees(trees_hz, hz_liquid, col='darkred', pch=16, cex=0.7)

```

### Geoprocessing

Now it's not enough to know where these large trees are. We would really like to
avoid any area within 200ft of them. Since the unit of measure for California
Albers is meters (see `st_crs(trees_hz)`), we want to avoid anywhere within 62m
of the danger trees. We can create a layer representing this data using
`st_buffer()`.

```
danger_zones = st_buffer(trees_hz, dist=62)
plot_trees(danger_zones, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)
```

This new data layer contains the information want. However, there are a lot of
overlapping polygons that make it difficult to tell what is going on visually.
We can combine multiple polygons into a single polygon using `st_union()`.

```
danger_zone = st_union(danger_zones)
plot_trees(danger_zone, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)
```

If we take a look at the data type though, it is no longer a data.frame. 

```
class(danger_zone)
```

This is going to be be a problem later on. Thankfully, there are other ways ways
of combining geometries. 

```
danger_zone <- group_by(danger_zones, hazard) |>
  summarize()
class(danger_zone)
```

We can also combine the liquefaction zones, since we don't need information
about individual zones.

```
liquid_zone = st_union(hz_liquid)
plot_trees(danger_zone, liquid_zone, col='red', border='darkred', pch=16, cex=0.7)
```

We are going to need a way to label these areas in liquefaction zones near
trees as dangerous, and we can do that by creating a new field in the 
`danger_zone` object called `status`. With data.frames we can create new
fields by using the dollar sign ($).

```
danger_zone$status <- 'Danger!'
```

### Even More Spatial Joins

While `st_intersection()` is a useful function, it only does one type of spatial
join. However, The `sf` function to do spatial joins is `st_join()`.

The `st_join()` function is a very powerful function that can do a lot of
different things depending on the value of various arguments. In this case we
are going to use it to label the streets that overlap with our danger zones with
the "Danger!" status. The join type will be the same as last time
(st_intersects), but we will also specify `left=TRUE`. This means include all of
the geometries and observations from the data layer, but only include data from
the second layer in the cases where it is related to the first, and none of the
geometries from the second layer.

```
danger_streets <- st_join(streets_ca, danger_zone, join=st_intersects,
                          left=TRUE) 
```

The options for the `join` argument (aka relations) have very specific
definitions, which may not align with the colloquial definitions of those words.
If you what to know what the definition of a particular relation is, or if you
are trying to figure out why your spatial join isn't working how you expected it
to, the Wikipedia article on the [DE-9IM model][de9im] provides in depth details
on each of the options.

[de9im]: https://en.wikipedia.org/wiki/DE-9IM


Now if we look at the `status` column in our `danger_streets` data.frame, there
are 328 streets with the status "Danger!" and 15,913 streets with missing data.
This is a problem, because we plot the `status` field, the streets with NA 
values will not be plotted.

```
table(danger_streets$status, exclude = FALSE)
```

We can fill in those missing values with text that indicates these streets are
okay to walk down.

```
danger_streets[is.na(danger_streets$status), 'status'] <- 'Have a nice walk :)'
```

### Plotting

We've already done some plotting in R using the plot function, but now we
finally have all of the data we need to create a map of all the places we should
avoid during an earthquake if we don't want large tree to fall on our head.

```
danger_title <- 'Street Safety Status Under Seismic Hazards'
plot(danger_streets[,'status'], key.pos = 1, main=danger_title)
```

Those are some pretty horrendous colors. Let's specify some better ones. We've
used the `col` argument before, but that just colors the entire geometry with
one color. And we want to color the streets based on their status. If
we look at the help file for `plot.sf`, we see there is an argument called 
`pal`, that allows us to specify a "palette function". This is a function that

```
?plot.sf
```

```
status_pal = function(n) {
  status_colors <- c('#ba001e', 'grey50')
  return(status_colors)
}

```

```
#with the legend
par(mar=c(1,1,2,1))
plot(danger_streets[,'status'], pal = status_pal, key.pos = 1, main=danger_title)

```


```
#with the shoreline
par(mar=c(4,1,2,1))
danger_title <- 'Street Safety Status Under Seismic Hazards'
plot(danger_streets[,'status'], pal = status_pal, key.pos = 1, main=danger_title)
plot(st_geometry(shoreline_ca), col='darkblue', lwd=2,  add=TRUE)


```

### Writing Data

If you want to be able to recreate this map, but don't want to have to go
through the data processing steps again, it can be helpful to save the data sets
you created in the process. The function to do this in the `sf` package is
`st_write()`. This is the equivalent of the "Make Permanent" functionality in
QGIS.

I'm going to save my data sets in a folder called "processed" in my data folder,
so that I know they have gone through data processing. I can create the folder
automatically in R using `dir.create()`.

```
dir.create('data/processed')
```

When using `st_write()` you have to specify which type of file to create using
the `driver` argument. To see a list of options for this argument, run 

```
st_drivers()
```

Let's create a geojson file. The driver for that is 'GeoJSON'. 

```
filename <- 'data/processed/street_danger_classification_san_francisco.geojson'
st_write(danger_streets, filename, driver='GeoJSON', delete_dsn=TRUE)
```

We can also create a shapefile.

```
shp_filename <- 'data/processed/san_francisco_shore_line.shp'
st_write(shoreline_ca, shp_filename, delete_dsn=TRUE)

```

