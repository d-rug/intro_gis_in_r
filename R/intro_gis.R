

# GIS in R with terra -----------------------------------------------------

library('terra')
library('rnaturalearth')

# Read in Data ------------------------------------------------------------
streets <- vect('data/raw/streetCenterlines.shp')
plot(streets)

shore <- vect('data/raw/Shoreline.shp')
plot(shore, col='skyblue', main='San Francisco Shoreline', border='darkblue')


hz <- vect('data/raw/seismic_hazard_zones_san_francisco.geojson')
hz_title <- 'Seismic Hazard Zones by Hazard Type in San Francisco'
plot(hz, 'hazard', main=hz_title)

trees_df <- read.csv('data/raw/Street_Tree_Map.csv')
head(trees_df)
dim(trees_df)



# Data Conversion ---------------------------------------------------------

shoreline = as.lines(shore)

trees <- vect(trees_df, geom=c('Longitude', 'Latitude'), crs='EPSG:4326')

usa <- ne_countries(country='united states of america', returnclass='sv')
plot(usa)
plot(trees, add=TRUE)


# Projection --------------------------------------------------------------

crs(streets, describe=TRUE)
crs(hz, describe=TRUE)
crs(trees, describe=TRUE)
crs(shoreline, describe=TRUE)

trees_ca <- project(trees, hz)
streets_ca <- project(streets, hz)
shore_ca <- project(shore, hz)
shoreline_ca <- project(shoreline, hz)


# Filtering ---------------------------------------------------------------

trees_ca <- trees_ca[!is.na(trees_ca$XCoord), ]
dim(trees_ca)

hz_ext = ext(hz)
trees_ca = crop(trees_ca, hz_ext)

plot(hz, col='lightblue', main=hz_title)
plot(trees_ca, col='darkgreen', pch='.', add=TRUE)

shore_ca <- crop(shore_ca, hz_ext)
shoreline_ca <- crop(shoreline_ca, hz_ext)

south_ext <- ext(-122.6, -122.39346, 37.6, 37.71)
south <- as.polygons(south_ext, crs=crs(streets))
south_ca <- project(south, hz)

better_shoreline <- erase(shoreline_ca, south_ca)
plot(better_shoreline)


# Function Interlude ------------------------------------------------------

plot_trees <- function(geom_top, geom_bottom, poly_color='lightblue', ...) {
  plot_title <- 'Street Trees in San Francisco'
  plot(geom_bottom, col=poly_color, main=plot_title,  axes=FALSE) 
  
  plot(geom_top, add=TRUE, ...)
  
}

plot_trees(trees_ca, hz, col='darkgreen', pch='.')


# Back to filtering -------------------------------------------------------

unique(hz$hazard)

hz_liquid <- hz[hz$hazard == 'liquefaction', ]
plot_trees(trees_ca, hz_liquid, col='darkgreen', pch='.')


summary(trees_ca$DBH)
hist(trees_ca$DBH)

is_big <- !is.na(trees_ca$DBH) & trees_ca$DBH<384 & trees_ca$DBH>=48
trees_big <- trees_ca[is_big, ]
plot_trees(trees_big, hz_liquid, col='darkgreen', pch=16, cex=0.5)



# Geoprocessing -----------------------------------------------------------

trees_hz <- intersect(trees_big, hz_liquid)
names(trees_big)
names(hz_liquid)
names(trees_hz)
trees_hz

plot_trees(trees_hz, hz_liquid, col='darkred', pch=16, cex=0.7)

danger_zones = buffer(trees_hz, width=62)
plot_trees(danger_zones, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)

danger_zone = aggregate(danger_zones)
plot_trees(danger_zone, hz_liquid, col='red', border='darkred', pch=16, cex=0.7)

hazard_zone = aggregate(hz, by='hazard')
liquid_zone = hazard_zone[ hazard_zone$hazard == 'liquefaction', ]
plot_trees(danger_zone, liquid_zone, col='red', border='darkred', pch=16, cex=0.7)


# Spatial Relations -------------------------------------------------------

in_danger_zone <- is.related(streets_ca, danger_zone, relation='intersects')
streets_ca$in_danger <- in_danger_zone

head(streets_ca)

streets_ca$status <- ifelse(streets_ca$in_danger, 'Danger!', 'Have a nice walk :)')
head(streets_ca)


# Plotting ----------------------------------------------------------------

danger_title <- 'Street Safety Status Under Seismic Hazards'
plot(streets_ca, 'status', main=danger_title, axes=FALSE)

plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),  main=danger_title, axes=FALSE)

plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),  main=danger_title, axes=FALSE)
plot(shore_ca, col=NULL, border=NULL, add=TRUE)
plot(better_shoreline, col='darkblue', lwd=2,  add=TRUE)

# Write Data --------------------------------------------------------------

dir.create('data/processed')

gdal(drivers=TRUE)


street_filename <- 'data/processed/street_classification_san_francisco.geojson'
writeVector(streets_ca, street_filename, filetype='GeoJSON', overwrite=TRUE)

sl_filename <- 'data/processed/san_francisco_shore_line.shp'
writeVector(better_shoreline, sl_filename, filetype='ESRI Shapefile', overwrite=TRUE)

shore_filename <- 'data/processed/san_francisco_shore_poly.geojson'
writeVector(shore_ca, shore_filename, filetype='GeoJSON', overwrite=TRUE)


# Extra -------------------------------------------------------------------
library('geodata')

geodata_path('data/geodata/')

coast_dem <- elevation_3s(-122.44, 37.75)
coast_dem
plot(coast_dem)

hz <- vect('data/raw/seismic_hazard_zones_san_francisco.geojson')
hz_ll = project(hz, coast_dem)



hz_land <- hz_ll[hz_ll$hazard == 'landslide', ]
hz_line <- as.lines(hz_land)

sf_dem <- crop(coast_dem, hz_land)



# Plotting ----------------------------------------------------------------

plot(sf_dem)
plot(hz_line, col='white', lwd=1.5, add=TRUE)

iplot <- plet(sf_dem)
lines(iplot, hz_line, col='white', lwd=1.5)


# Elevation Calculations --------------------------------------------------

sf_dem2 <- sf_dem*2

names(sf_dem2) <- 'landslide_dist'

landslide_range = function(x) {
  if (all(is.na(x))) {
    d <- 0
  } else {
    d <- diff(range(x, na.rm=TRUE))
  }
  
  if (d==0) {
    d <- 10
  }
  
  return(d)
}

hz_land = extract(sf_dem2, hz_land, fun=landslide_range, bind=TRUE)



hz_buff_list = lapply(seq_along(hz_land), function(i) {
  buffer(hz_land[i, ], width = hz_land$landslide_dist[i])
})

hz_buff = do.call('rbind', hz_buff_list)

hz_buff = aggregate(hz_buff)

hz_buff_line = as.lines(hz_buff)

# More plot ---------------------------------------------------------------

iplot <- plet(sf_dem)
iplot <- lines(iplot, hz_line, col='white', lwd=1)
lines(iplot, hz_buff_line, col='orange', lwd=1.5)


########################## RESTART R HERE #################################


# Vector GIS in R with sf -------------------------------------------------

library('sf')
library('dplyr')
library('rnaturalearth')
library('RColorBrewer')

# Read in data ------------------------------------------------------------

streets <- st_read('data/raw/streetCenterlines.shp')

streets_geom <- st_geometry(streets)
plot(streets_geom)

shore <- st_read('data/raw/Shoreline.shp')
plot(st_geometry(shore), main='San Francisco Shoreline')

hz <- st_read('data/raw/seismic_hazard_zones_san_francisco.geojson')

hz_title <- 'Seismic Hazard Zones by Hazard Type in San Francisco'
plot(hz[,'hazard'], key.pos=1, main=hz_title)

trees_df <- read.csv('data/raw/Street_Tree_Map.csv')
head(trees_df)

# Data Conversion ---------------------------------------------------------

shoreline = st_cast(shore, 'MULTILINESTRING')

trees_df <- filter(trees_df, !is.na(Longitude))
trees <- st_as_sf(x=trees_df,
                  coords=c('Longitude', 'Latitude'),
                  crs=4326)


trees_geom <- st_geometry(trees)
plot(trees_geom)


usa <- ne_countries(country='united states of america')
plot(st_geometry(usa))
plot(trees_geom, add=TRUE)


# Projection --------------------------------------------------------------

st_crs(streets)$input
st_crs(hz)$input
st_crs(trees)$input
st_crs(shoreline)$input


trees_ca <- st_transform(trees, crs=3310)
streets_ca <- st_transform(streets, crs=3310)
shoreline_ca <- st_transform(shoreline, crs=3310)

trees_ca <- st_crop(trees_ca, hz)
shoreline_ca <- st_crop(shoreline_ca, hz)
streets_ca <- st_crop(streets_ca, hz)


#plot(hz[,'hazard'], key.pos=1, main=hz_title)
plot(st_geometry(hz), col='lightblue', main=hz_title)
plot(st_geometry(trees_ca), col='darkgreen', pch='.', add=TRUE)
plot(st_geometry(shoreline_ca), col='darkblue', lwd=2, add=TRUE)


# Function ----------------------------------------------------------------
plot_trees <- function(points, polys, poly_color='lightblue', ...) {
  plot_title <- 'Street Trees in San Francisco'
  plot(st_geometry(polys), col=poly_color, main=plot_title, extent=points)
  
  plot(st_geometry(points), add=TRUE, ...)
  
}

# Filtering ---------------------------------------------------------------

hz_liquid = hz[hz$hazard == 'liquefaction',]

hist(trees_ca$DBH)
has_dbh <- !is.na(trees_ca$DBH) & trees_ca$DBH<384
trees_dbh <- trees_ca[has_dbh, ]

is_big <- !is.na(trees_ca$DBH) & trees_ca$DBH > 48
trees_big <- trees_ca[is_big, ]

plot_trees(trees_ca, hz, col='darkgreen', pch='.')
plot_trees(trees_big, hz, col='darkgreen', pch=16, cex=0.5)

trees_big_hz <- st_intersection(trees_big, hz_liquid)

plot_trees(trees_big_hz, hz_liquid, col='red', pch=16, cex=0.7)

plot_trees(trees_big_hz, streets_ca, poly_color = 'black', col='red', pch=16, cex=0.7)

danger_zones <- st_buffer(trees_big_hz, 62)


danger_zone_sfc <- st_union(danger_zones)
class(danger_zone_sfc)

danger_zone <- group_by(danger_zones, hazard) |>
  summarize()
class(danger_zone)

#alternatively aggregate() in terra

plot_trees(danger_zone, hz_liquid, col='red')

danger_zone$status <- 'Danger!'


# More spatial joins ------------------------------------------------------


danger_streets <- st_join(streets_ca, danger_zone, join=st_intersects,
                          left=TRUE) 

danger_streets <-   st_crop(danger_streets, hz)


danger_streets[is.na(danger_streets$status), 'status'] <- 'Have a nice walk :)'



# Plotting ----------------------------------------------------------------

status_pal = function(n) {
  status_colors <- c('#ba001e', 'grey50')
  return(status_colors)
}

#with the shoreline
par(mar=c(1,1,2,1))
danger_title <- 'Street Safety Status Under Seismic Hazards'
plot(st_geometry(shoreline_ca), col='darkblue', lwd=2, main=danger_title, 
     extent=danger_streets)
plot(danger_streets[,'status'], pal = status_pal, key.pos = 1, add=TRUE)

#with the legend
par(mar=c(1,1,2,1))
plot(danger_streets[,'status'], pal = status_pal, key.pos = 1, main=danger_title)


# Write Data --------------------------------------------------------------

dir.create('data/processed')
st_drivers()

st_write(danger_streets, 'data/processed/danger_streets.geojson', 
         delete_dsn = TRUE)
st_write(danger_zone, 'data/processed/danger_zone.geojson')
st_write(shoreline_ca, 'data/processed/san_francisco_shore_line.geojson')


